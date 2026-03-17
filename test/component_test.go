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
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
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

	albName := atmos.Output(s.T(), options, "alb_name")
	albARN := atmos.Output(s.T(), options, "alb_arn")
	albARNSuffix := atmos.Output(s.T(), options, "alb_arn_suffix")

	assert.True(s.T(), strings.HasPrefix(albARNSuffix, fmt.Sprintf("app/%s", albName)))

	awsAccountID := aws.GetAccountId(s.T())

	expectedArn := fmt.Sprintf("arn:aws:elasticloadbalancing:%s:%s:loadbalancer/%s", awsRegion, awsAccountID, albARNSuffix)
	assert.Equal(s.T(), expectedArn, albARN)

	client := awshelper.NewElbV2Client(s.T(), awsRegion)

	loadBalancers, err := client.DescribeLoadBalancers(context.Background(), &elasticloadbalancingv2.DescribeLoadBalancersInput{
		LoadBalancerArns: []string{albARN},
	})
	assert.NoError(s.T(), err)

	if len(loadBalancers.LoadBalancers) == 0 {
		s.T().Fatal("No load balancers found")
	}
	loadBalancer := loadBalancers.LoadBalancers[0]
	albDNSName := atmos.Output(s.T(), options, "alb_dns_name")
	assert.Equal(s.T(), *loadBalancer.DNSName, albDNSName)

	albZoneID := atmos.Output(s.T(), options, "alb_zone_id")
	assert.Equal(s.T(), *loadBalancer.CanonicalHostedZoneId, albZoneID)

	securityGroupID := atmos.Output(s.T(), options, "security_group_id")
	assert.Equal(s.T(), loadBalancer.SecurityGroups[0], securityGroupID)

	targetGroups, err := client.DescribeTargetGroups(context.Background(), &elasticloadbalancingv2.DescribeTargetGroupsInput{
		LoadBalancerArn: &albARN,
	})
	assert.NoError(s.T(), err)

	if len(targetGroups.TargetGroups) == 0 {
		s.T().Fatal("No target groups found")
	}
	targetGroup := targetGroups.TargetGroups[0]
	defaultTargetGroupARN := atmos.Output(s.T(), options, "default_target_group_arn")
	assert.Equal(s.T(), *targetGroup.TargetGroupArn, defaultTargetGroupARN)

	listenerARNS := atmos.OutputList(s.T(), options, "listener_arns")
	assert.Equal(s.T(), 2, len(listenerARNS))

	listeners, err := client.DescribeListeners(context.Background(), &elasticloadbalancingv2.DescribeListenersInput{LoadBalancerArn: &albARN})
	assert.NoError(s.T(), err)

	assert.Equal(s.T(), 2, len(listeners.Listeners))

	httpRedirectListenerARN := atmos.Output(s.T(), options, "http_redirect_listener_arn")
	httpsListenerARN := atmos.Output(s.T(), options, "https_listener_arn")

	for _, listener := range listeners.Listeners {
		if *listener.Port == 443 {
			assert.Equal(s.T(), *listener.ListenerArn, httpsListenerARN)
			assert.EqualValues(s.T(), "HTTPS", listener.Protocol)
		} else {
			assert.Equal(s.T(), *listener.ListenerArn, httpRedirectListenerARN)
			assert.EqualValues(s.T(), "HTTP", listener.Protocol)
		}
		assert.Contains(s.T(), listenerARNS, *listener.ListenerArn)
	}

	accessLogsBucketID := atmos.Output(s.T(), options, "access_logs_bucket_id")
	assert.Equal(s.T(), "", accessLogsBucketID)

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

	primaryDomain := fmt.Sprintf("%s.cptest.test-automation.app", strings.ToLower(random.UniqueId()))
	primaryInputs := map[string]any{
		"domain_names": []string{primaryDomain},
	}
	suite.AddDependency(t, "dns-primary", "default-test", &primaryInputs)

	subdomain := strings.ToLower(random.UniqueId())
	delegatedInputs := map[string]any{
		"zone_config": []map[string]any{
			{
				"subdomain": subdomain,
				"zone_name": primaryDomain,
			},
		},
	}
	suite.AddDependency(t, "dns-delegated", "default-test", &delegatedInputs)
	suite.AddDependency(t, "acm", "default-test", nil)
	helper.Run(t, suite)
}
