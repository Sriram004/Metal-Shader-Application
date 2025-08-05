#include <metal_stdlib>
using namespace metal;

kernel void edgeDetection(
    texture2d<float, access::read>  inTexture  [[ texture(0) ]],
    texture2d<float, access::write> outTexture [[ texture(1) ]],
    uint2 gid [[ thread_position_in_grid ]])
{
    if (gid.x <= 0 || gid.y <= 0 ||
        gid.x >= (inTexture.get_width() - 1) ||
        gid.y >= (inTexture.get_height() - 1)) {
        outTexture.write(float4(0), gid);
        return;
    }

    float3x3 Gx = float3x3(
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1);

    float3x3 Gy = float3x3(
        -1, -2, -1,
         0,  0,  0,
         1,  2,  1);

    float4 sumX = float4(0.0);
    float4 sumY = float4(0.0);

    for (int j = -1; j <= 1; ++j) {
        for (int i = -1; i <= 1; ++i) {
            float4 currentPixel = inTexture.read(gid + uint2(i, j));
            sumX += currentPixel * Gx[j + 1][i + 1];
            sumY += currentPixel * Gy[j + 1][i + 1];
        }
    }

    float4 magnitude = sqrt((sumX * sumX) + (sumY * sumY));
    outTexture.write(magnitude, gid);
}
