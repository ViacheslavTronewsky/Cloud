#!/bin/bash

LoadBalancer="Name=LoadBalancer,Value=app/Lab4-ELB/19cbc40ab64117e6"
TargetGroup="Name=TargetGroup,Value=targetgroup/Lab4-Target-Group/9af6dde298e792eb"

topic_arn=$(aws sns create-topic \
            --name healthy_check \
            --output text)

echo "Created SNS Topic"

aws sns subscribe \
        --topic-arn $topic_arn \
        --protocol email \
        --notification-endpoint tronewsky2@gmail.com

echo "Subscribed to SNS Topic with my email"


aws cloudwatch put-metric-alarm \
            --alarm-name healthy_check \
            --alarm-description "Healthy Alarm" \
            --namespace AWS/ApplicationELB \
            --dimensions $LoadBalancer $TargetGroup \
            --period 300 \
            --evaluation-periods 1 \
            --threshold 2 \
            --comparison-operator LessThanThreshold \
            --metric-name HealthyHostCount \
            --alarm-actions $topic_arn \
            --statistic Minimum

echo "Created alarm metric"


aws elbv2 deregister-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:381738705499:targetgroup/Lab4-Target-Group/9af6dde298e792eb --targets Id=i-0cf5e2b6f6bcbaaac

aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-1:381738705499:targetgroup/Lab4-Target-Group/9af6dde298e792eb --targets Id=i-0cf5e2b6f6bcbaaac