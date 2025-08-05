#include <metal_stdlib>
using namespace metal;

kernel void chromaticAberration(
    texture2d<float, access::read>  inTexture  [[ texture(0) ]],
    texture2d<float, access::write> outTexture [[ texture(1) ]],
    constant float&                 offset      [[ buffer(0) ]],
    uint2 gid [[ thread_position_in_grid ]])
{
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();

    if (gid.x >= width || gid.y >= height) return;

    float2 texCoord = float2(gid) / float2(width, height);

    float2 offsetUV = float2(offset / float(width), offset / float(height));

    // Sample different channels with slight offsets
    float red   = inTexture.sample(sampler(coord::normalized), texCoord + offsetUV).r;
    float green = inTexture.sample(sampler(coord::normalized), texCoord).g;
    float blue  = inTexture.sample(sampler(coord::normalized), texCoord - offsetUV).b;

    float4 color = float4(red, green, blue, 1.0);
    outTexture.write(color, gid);
}
