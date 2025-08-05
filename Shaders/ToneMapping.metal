#include <metal_stdlib>
using namespace metal;

// Simple filmic tone mapping using Reinhard operator
kernel void toneMapping(
    texture2d<float, access::read>  inTexture  [[ texture(0) ]],
    texture2d<float, access::write> outTexture [[ texture(1) ]],
    constant float&                 exposure    [[ buffer(0) ]],
    uint2 gid [[ thread_position_in_grid ]])
{
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;

    float4 hdrColor = inTexture.read(gid);
    float3 mapped = hdrColor.rgb * exposure;
    mapped = mapped / (mapped + float3(1.0)); // Reinhard tone mapping

    float3 gammaCorrected = pow(mapped, float3(1.0 / 2.2));
    outTexture.write(float4(gammaCorrected, hdrColor.a), gid);
}
