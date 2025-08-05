#include <metal_stdlib>
using namespace metal;

// 2D texture input/output
kernel void gaussianBlur(
    texture2d<float, access::read>  inTexture  [[ texture(0) ]],
    texture2d<float, access::write> outTexture [[ texture(1) ]],
    constant float*                 kernel      [[ buffer(0) ]],
    constant uint&                  kernelSize  [[ buffer(1) ]],
    uint2 gid [[ thread_position_in_grid ]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float4 color = float4(0.0);
    int radius = int(kernelSize / 2);

    for (int y = -radius; y <= radius; ++y) {
        for (int x = -radius; x <= radius; ++x) {
            int2 coord = int2(gid) + int2(x, y);
            if (coord.x < 0 || coord.x >= int(inTexture.get_width()) ||
                coord.y < 0 || coord.y >= int(inTexture.get_height())) continue;

            float weight = kernel[(y + radius) * kernelSize + (x + radius)];
            color += inTexture.read(uint2(coord)) * weight;
        }
    }

    outTexture.write(color, gid);
}
