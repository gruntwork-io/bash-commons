package integration_test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/git"
	"github.com/gruntwork-io/terratest/modules/packer"
)

func TestDynamicUbuntuWait(t *testing.T) {
	t.Parallel()

	region := aws.GetRandomStableRegion(t, nil, nil)
	instance_type := aws.GetRecommendedInstanceType(t, region, []string{"t2.micro", "t3.micro"})
	buildOptions := &packer.Options{
		Template: "../examples/dynamic-ubuntu-wait/packer-build.json",
		Vars: map[string]string{
			"aws_region":    region,
			"instance_type": instance_type,
			"module_branch": git.GetCurrentBranchName(t),
		},
	}
	artifactID := packer.BuildArtifact(t, buildOptions)
	aws.DeleteAmiAndAllSnapshots(t, region, artifactID)
}
