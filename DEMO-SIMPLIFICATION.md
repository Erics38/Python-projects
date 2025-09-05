# Demo Infrastructure Simplification Plan

## Current Issues with Production-Scale Infrastructure

The current infrastructure is designed for production with:
- **Multi-AZ deployment** (2+ Availability Zones)
- **Multiple NAT Gateways** (1 per AZ = costly)
- **Complex security group dependencies**
- **Multiple subnets** (public/private per AZ)
- **Enterprise-grade monitoring and alerting**
- **WAF, security hardening, Lambda@Edge**

This complexity is causing:
- **Resource limit issues** (EIP limits, security group rules)
- **Dependency conflicts** (circular references)
- **High cost** ($45+ per month for NAT Gateways alone)
- **Deployment complexity** (10+ minute deployments)

## Simplified Demo Architecture

### Simplified Components:
```
┌─────────────────────────────────────────────┐
│                 Demo VPC                    │
│  ┌─────────────────┐  ┌─────────────────┐   │
│  │  Public Subnet  │  │ Private Subnet  │   │
│  │   (us-east-1a)  │  │  (us-east-1a)   │   │
│  │                 │  │                 │   │
│  │  ┌───────────┐  │  │  ┌───────────┐  │   │
│  │  │    ALB    │  │  │  │    ECS    │  │   │
│  │  └───────────┘  │  │  └───────────┘  │   │
│  └─────────────────┘  └─────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────────┐ │
│  │            RDS (Public)             │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Key Simplifications:
1. **Single AZ** - us-east-1a only
2. **One NAT Gateway** - instead of 2
3. **Public RDS** - no private subnet complexity
4. **Minimal Security Groups** - essential rules only
5. **No WAF/Security Hardening** - for demo
6. **Basic Monitoring** - essential only
7. **HTTP only** - no SSL certificates
8. **Single container** - frontend only

## Implementation Plan

### Phase 1: Create Simplified Demo Configuration
1. Create `environments/demo-simple.tfvars`
2. Modify main.tf to use single AZ
3. Simplify networking module
4. Remove security hardening module
5. Simplify monitoring

### Phase 2: Test Demo Deployment
1. Deploy simplified version
2. Verify basic functionality
3. Document working configuration

### Phase 3: Scale Up When Ready
1. Add production features incrementally
2. Multi-AZ when stability is proven
3. Security hardening for production
4. Full monitoring and alerting

## Cost Comparison

### Current Production Setup:
- NAT Gateways: $45/month (2 × $22.50)
- EIPs: $3.60/month (2 × $1.80)
- RDS Multi-AZ: $25/month
- **Total: ~$75/month**

### Simplified Demo:
- NAT Gateway: $22.50/month (1 × $22.50)
- EIP: $1.80/month (1 × $1.80)
- RDS Single AZ: $12/month
- **Total: ~$36/month** (52% cost reduction)

## Next Steps

1. **Immediate**: Clean up existing resources completely
2. **Create**: Simplified demo configuration
3. **Test**: Deploy and verify basic functionality
4. **Document**: Working demo for future scaling