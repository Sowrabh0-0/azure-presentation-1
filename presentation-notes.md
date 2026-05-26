# Azure Hub-Spoke Presentation Notes

## Files

- `presentation.html` - 10-slide browser presentation.
- `inbound-host-routing-flow.excalidraw` - editable inbound App Gateway flow.
- `outbound-onprem-vpn-flow.excalidraw` - editable outbound, private endpoint, and VPN flow.
- `app-outbound-traffic-flow.excalidraw` - editable actual app outbound flow from Docker Compose to DB, internet, and on-prem routes.
- `d__opslora_opslora_azure-infra-architecture_presentation-1-arc-2.png` - full architecture diagram used in slide 2.

## How to present

Open `presentation.html` in a browser and use the left/right arrow keys.

Use these URLs for the live demo:

```text
http://opslora.com
http://pronunt.com
```

## Key speaking flow

1. Start with the goal: two three-tier apps automated with Terraform and deployed into hub-spoke Azure networking.
2. Explain why the hub exists: shared ingress, firewall, bastion, VPN gateway, and governance.
3. Explain why spokes exist: workload isolation, separate CIDR ranges, regional placement, and targeted NSGs/UDRs.
4. Walk inbound traffic: DNS -> App Gateway WAF -> host listener -> backend pool -> internal load balancer -> VMSS frontend.
5. Walk security controls: WAF blocks web attacks, NSGs restrict subnet access, Firewall controls egress/on-prem flows, private endpoints keep databases private.
6. Walk outbound/data traffic: app subnets use private DNS/private endpoints for databases and UDRs through Azure Firewall for default internet paths.
7. Walk hybrid connectivity: on-prem strongSwan -> Azure VPN Gateway -> hub peering gateway transit -> spokes.
8. Close with scalability and HA: App Gateway autoscale, VMSS min 1 max 3, health probes, DDoS plan, managed data services, multi-region workload placement.

## Actual outbound traffic from the apps

There are three different outbound patterns:

1. In-container traffic:
   - Nginx proxies browser paths to frontend/API containers on the same Docker Compose network.
   - This does not leave the VMSS instance unless the container calls an external dependency.

2. Database traffic:
   - Opslora services resolve Azure SQL private DNS and connect to SQL through the Opslora private endpoint subnet.
   - Pronunt services resolve Cosmos DB Mongo private DNS and connect through the Pronunt private endpoint subnet.
   - The database path stays on private IP space and does not use public database endpoints.

3. Internet and hybrid traffic:
   - Image pulls, package updates, GitHub/OpenAI calls, or any default internet path match the spoke route table `0.0.0.0/0`.
   - That route sends traffic to Azure Firewall in the hub.
   - Azure Firewall allows only the required network rules such as DNS, HTTP, and HTTPS.
   - Traffic to `10.30.0.0/24` follows the on-prem UDR path through Azure Firewall/VPN Gateway depending on the route and gateway transit.

## Architecture verification note

The diagram is aligned with the implementation. The Terraform implementation adds two practical details that make the design work cleanly:

- Dedicated private endpoint subnets in each spoke.
- Regional internal load balancers in front of VMSS instances, using stable private IPs for Application Gateway backend pools.
