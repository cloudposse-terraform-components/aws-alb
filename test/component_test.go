package test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2"
	"github.com/cloudposse/test-helpers/pkg/atmos"
	helper "github.com/cloudposse/test-helpers/pkg/atmos/aws-component-helper"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type validationOption struct {
	DomainName          string `json:"domain_name"`
	ResourceRecordName  string `json:"resource_record_name"`
	ResourceRecordType  string `json:"resource_record_type"`
	ResourceRecordValue string `json:"resource_record_value"`
}

type zone struct {
	Arn               string            `json:"arn"`
	Comment           string            `json:"comment"`
	DelegationSetId   string            `json:"delegation_set_id"`
	ForceDestroy      bool              `json:"force_destroy"`
	Id                string            `json:"id"`
	Name              string            `json:"name"`
	NameServers       []string          `json:"name_servers"`
	PrimaryNameServer string            `json:"primary_name_server"`
	Tags              map[string]string `json:"tags"`
	TagsAll           map[string]string `json:"tags_all"`
	Vpc               []struct {
		ID     string `json:"vpc_id"`
		Region string `json:"vpc_region"`
	} `json:"vpc"`
	ZoneID string `json:"zone_id"`
}

func TestComponent(t *testing.T) {
	// Define the AWS region to use for the tests
	awsRegion := "us-east-2"

	// Initialize the test fixture
	fixture := helper.NewFixture(t, "../", awsRegion, "test/fixtures")

	// Ensure teardown is executed after the test
	defer fixture.TearDown()
	fixture.SetUp(&atmos.Options{})

	// Define the test suite
	fixture.Suite("default", func(t *testing.T, suite *helper.Suite) {
		suite.AddDependency("vpc", "default-test")

		// Setup phase: Create DNS zones for testing
		suite.Setup(t, func(t *testing.T, atm *helper.Atmos) {
			basicDomain := "components.cptest.test-automation.app"

			// Deploy the delegated DNS zone
			inputs := map[string]interface{}{
				"zone_config": []map[string]interface{}{
					{
						"subdomain": suite.GetRandomIdentifier(),
						"zone_name": basicDomain,
					},
				},
			}
			atm.GetAndDeploy("dns-delegated", "default-test", inputs)
			atm.GetAndDeploy("acm", "default-test", map[string]interface{}{})
		})

		// Teardown phase: Destroy the DNS zones created during setup
		suite.TearDown(t, func(t *testing.T, atm *helper.Atmos) {
			atm.GetAndDestroy("acm", "default-test", map[string]interface{}{})

			// Deploy the delegated DNS zone
			inputs := map[string]interface{}{
				"zone_config": []map[string]interface{}{
					{
						"subdomain": suite.GetRandomIdentifier(),
						"zone_name": "components.cptest.test-automation.app",
					},
				},
			}
			atm.GetAndDestroy("dns-delegated", "default-test", inputs)
		})

		// Test phase: Validate the functionality of the ALB component
		suite.Test(t, "basic", func(t *testing.T, atm *helper.Atmos) {
			t.Skip("There is a bug - ALB Component can not get ACM certificate of the current version delegated DNS component. Read more https://github.com/cloudposse-terraform-components/aws-alb/issues/16")
			defer atm.GetAndDestroy("alb/basic", "default-test", map[string]interface{}{})
			component := atm.GetAndDeploy("alb/basic", "default-test", map[string]interface{}{})
			assert.NotNil(t, component)
		})

		suite.Test(t, "acm", func(t *testing.T, atm *helper.Atmos) {
			defer atm.GetAndDestroy("alb/acm", "default-test", map[string]interface{}{})
			component := atm.GetAndDeploy("alb/acm", "default-test", map[string]interface{}{})
			assert.NotNil(t, component)

			alb_name := atm.Output(component, "alb_name")
			alb_arn := atm.Output(component, "alb_arn")
			alb_arn_suffix := atm.Output(component, "alb_arn_suffix")

			assert.True(t, strings.HasPrefix(alb_arn_suffix, fmt.Sprintf("app/%s", alb_name)))

			expectedArn := fmt.Sprintf("arn:aws:elasticloadbalancing:%s:%s:loadbalancer/%s", awsRegion, fixture.AwsAccountId, alb_arn_suffix)
			assert.Equal(t, expectedArn, alb_arn)

			client := NewElbV2Client(t, awsRegion)

			loadBalancers, err := client.DescribeLoadBalancers(context.Background(), &elasticloadbalancingv2.DescribeLoadBalancersInput{
				LoadBalancerArns: []string{alb_arn},
			})
			assert.NoError(t, err)

			loadBalancer := loadBalancers.LoadBalancers[0]

			alb_dns_name := atm.Output(component, "alb_dns_name")
			assert.Equal(t, *loadBalancer.DNSName, alb_dns_name)

			alb_zone_id := atm.Output(component, "alb_zone_id")
			assert.Equal(t, *loadBalancer.CanonicalHostedZoneId, alb_zone_id)

			security_group_id := atm.Output(component, "security_group_id")
			assert.Equal(t, loadBalancer.SecurityGroups[0], security_group_id)

			targetGroups, err := client.DescribeTargetGroups(context.Background(), &elasticloadbalancingv2.DescribeTargetGroupsInput{
				LoadBalancerArn: &alb_arn,
			})
			assert.NoError(t, err)

			targetGroup := targetGroups.TargetGroups[0]

			default_target_group_arn := atm.Output(component, "default_target_group_arn")
			assert.Equal(t, *targetGroup.TargetGroupArn, default_target_group_arn)

			listener_arns := atm.OutputList(component, "listener_arns")
			assert.Equal(t, 2, len(listener_arns))

			listeners, err := client.DescribeListeners(context.Background(), &elasticloadbalancingv2.DescribeListenersInput{LoadBalancerArn: &alb_arn})
			assert.NoError(t, err)

			assert.Equal(t, 2, len(listeners.Listeners))

			http_redirect_listener_arn := atm.Output(component, "http_redirect_listener_arn")
			https_listener_arn := atm.Output(component, "https_listener_arn")

			for _, listener := range listeners.Listeners {
				if *listener.Port == 443 {
					assert.Equal(t, *listener.ListenerArn, https_listener_arn)
					assert.EqualValues(t, "HTTPS", listener.Protocol)
				} else {
					assert.Equal(t, *listener.ListenerArn, http_redirect_listener_arn)
					assert.EqualValues(t, "HTTP", listener.Protocol)
				}
				assert.Contains(t, listener_arns, *listener.ListenerArn)
			}

			access_logs_bucket_id := atm.Output(component, "access_logs_bucket_id")
			assert.Equal(t, "", access_logs_bucket_id)
		})
	})
}

// NewElbV2Client creates en ELB client.
func NewElbV2Client(t *testing.T, region string) *elasticloadbalancingv2.Client {
	client, err := NewElbV2ClientE(t, region)
	require.NoError(t, err)

	return client
}

// NewElbV2ClientE creates an ELB client.
func NewElbV2ClientE(t *testing.T, region string) (*elasticloadbalancingv2.Client, error) {
	sess, err := aws.NewAuthenticatedSession(region)
	if err != nil {
		return nil, err
	}
	return elasticloadbalancingv2.NewFromConfig(*sess), nil
}
