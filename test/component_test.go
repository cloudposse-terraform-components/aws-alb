package test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2"
	"github.com/cloudposse/test-helpers/pkg/atmos"
	helper "github.com/cloudposse/test-helpers/pkg/atmos/component-helper"
	awshelper "github.com/cloudposse/test-helpers/pkg/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
)

type ComponentSuite struct {
	helper.TestSuite
}

func (s *ComponentSuite) TestBasic() {
	const component = "alb/basic"
	const stack = "default-test"
	const awsRegion = "us-east-2"

	s.T().Skip("There is a bug - ALB Component can not get ACM certificate of the current version delegated DNS component. Read more https://github.com/cloudposse-terraform-components/aws-alb/issues/16")
	defer s.DestroyAtmosComponent(s.T(), component, stack, nil)
	options, _ := s.DeployAtmosComponent(s.T(), component, stack, nil)
	assert.NotNil(s.T(), options)

	s.DriftTest(component, stack, nil)
}

func (s *ComponentSuite) TestAcm() {
	const component = "alb/acm"
	const stack = "default-test"
	const awsRegion = "us-east-2"

	defer s.DestroyAtmosComponent(s.T(), component, stack, nil)
	options, _ := s.DeployAtmosComponent(s.T(), component, stack, nil)

	assert.NotNil(s.T(), options)

	alb_name := atmos.Output(s.T(), options, "alb_name")
	alb_arn := atmos.Output(s.T(), options, "alb_arn")
	alb_arn_suffix := atmos.Output(s.T(), options, "alb_arn_suffix")

	assert.True(s.T(), strings.HasPrefix(alb_arn_suffix, fmt.Sprintf("app/%s", alb_name)))

	awsAccountId := aws.GetAccountId(s.T())

	expectedArn := fmt.Sprintf("arn:aws:elasticloadbalancing:%s:%s:loadbalancer/%s", awsRegion, awsAccountId, alb_arn_suffix)
	assert.Equal(s.T(), expectedArn, alb_arn)

	client := awshelper.NewElbV2Client(s.T(), awsRegion)

	loadBalancers, err := client.DescribeLoadBalancers(context.Background(), &elasticloadbalancingv2.DescribeLoadBalancersInput{
		LoadBalancerArns: []string{alb_arn},
	})
	assert.NoError(s.T(), err)

	loadBalancer := loadBalancers.LoadBalancers[0]

	alb_dns_name := atmos.Output(s.T(), options, "alb_dns_name")
	assert.Equal(s.T(), *loadBalancer.DNSName, alb_dns_name)

	alb_zone_id := atmos.Output(s.T(), options, "alb_zone_id")
	assert.Equal(s.T(), *loadBalancer.CanonicalHostedZoneId, alb_zone_id)

	security_group_id := atmos.Output(s.T(), options, "security_group_id")
	assert.Equal(s.T(), loadBalancer.SecurityGroups[0], security_group_id)

	targetGroups, err := client.DescribeTargetGroups(context.Background(), &elasticloadbalancingv2.DescribeTargetGroupsInput{
		LoadBalancerArn: &alb_arn,
	})
	assert.NoError(s.T(), err)

	targetGroup := targetGroups.TargetGroups[0]

	default_target_group_arn := atmos.Output(s.T(), options, "default_target_group_arn")
	assert.Equal(s.T(), *targetGroup.TargetGroupArn, default_target_group_arn)

	listener_arns := atmos.OutputList(s.T(), options, "listener_arns")
	assert.Equal(s.T(), 2, len(listener_arns))

	listeners, err := client.DescribeListeners(context.Background(), &elasticloadbalancingv2.DescribeListenersInput{LoadBalancerArn: &alb_arn})
	assert.NoError(s.T(), err)

	assert.Equal(s.T(), 2, len(listeners.Listeners))

	http_redirect_listener_arn := atmos.Output(s.T(), options, "http_redirect_listener_arn")
	https_listener_arn := atmos.Output(s.T(), options, "https_listener_arn")

	for _, listener := range listeners.Listeners {
		if *listener.Port == 443 {
			assert.Equal(s.T(), *listener.ListenerArn, https_listener_arn)
			assert.EqualValues(s.T(), "HTTPS", listener.Protocol)
		} else {
			assert.Equal(s.T(), *listener.ListenerArn, http_redirect_listener_arn)
			assert.EqualValues(s.T(), "HTTP", listener.Protocol)
		}
		assert.Contains(s.T(), listener_arns, *listener.ListenerArn)
	}

	access_logs_bucket_id := atmos.Output(s.T(), options, "access_logs_bucket_id")
	assert.Equal(s.T(), "", access_logs_bucket_id)

	s.DriftTest(component, stack, nil)

}


func (s *ComponentSuite) TestEnabledFlag() {
	const component = "alb/disabled"
	const stack = "default-test"
	s.VerifyEnabledFlag(component, stack, nil)
}

func TestRunSuite(t *testing.T) {
	suite := new(ComponentSuite)

	suite.AddDependency(t, "vpc", "default-test", nil)

	subdomain := strings.ToLower(random.UniqueId())
	inputs := map[string]interface{}{
		"zone_config": []map[string]interface{}{
			{
				"subdomain": subdomain,
				"zone_name": "components.cptest.test-automation.app",
			},
		},
	}
	suite.AddDependency(t, "dns-delegated", "default-test", &inputs)
	suite.AddDependency(t, "acm", "default-test", nil)
	helper.Run(t, suite)
}
