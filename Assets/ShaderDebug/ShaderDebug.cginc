
#ifndef SHADER_DEBUG_INCLUDED
#define SHADER_DEBUG_INCLUDED


float SphereMask(float pos, float center, float radius)
{
    float maskA = ((pos - center) > radius) ? 0 : 1;
    float maskB = ((center - pos) > radius) ? 0 : 1;
    return maskA * maskB;
}

float DebugValue(in sampler2D numberStripTex, in sampler2D numberPeriodTex, float maxNumberOfDigits, in float2 uv, in float inputValue)
{
    // texture corpping
    float4 upperLeftLowerRight = float4(0, 0.6, 1, 0.4);
    float2 cropUV = (uv + (upperLeftLowerRight.xy * -1)) / (upperLeftLowerRight.zw - upperLeftLowerRight.xy);
    float2 cropMask = SphereMask(cropUV.y, 0.5, 0.5);

    float2 numStripUV = cropUV * float2(2, 0.1);
    float tmpU = (1 - numStripUV.x) * maxNumberOfDigits;
    float tmpFrac = frac(tmpU);

    // decimal mark
    float2 decimalUV = float2((((maxNumberOfDigits * 2) * (cropUV.x - 0.5)) + 0.5), -cropUV.y + 1);
    float decimalColor = tex2D(numberPeriodTex, decimalUV).x;

    // negative symbol
    float2 symbolUV = float2(tmpFrac, cropUV.y);
    float absValue = abs(inputValue);
    float ceilU = ceil(clamp(tmpU, 0, 10));
    float tmpSymMaskA = absValue / pow(10, ceilU + 3);
    tmpSymMaskA = (tmpSymMaskA > 0.00001) ? 1 : 0;
    float tmpSymMaskB = absValue / pow(10, ceilU + 4);
    tmpSymMaskB = (tmpSymMaskB > 0.00001) ? 1 : 0;
    float symbolColor = 0;
    if (inputValue < 0)
    {
        symbolColor = (tmpSymMaskA > tmpSymMaskB) ? tex2D(numberPeriodTex, symbolUV).y : 0;
    }


    float tmpLerpB = pow(10, floor(clamp(abs(clamp(tmpU, -10, 0)) - 1, 0, 10)));
    tmpLerpB = tmpLerpB * (absValue + absValue / 1000000);
    tmpLerpB = floor(frac(tmpLerpB) * 10) / 10;
    tmpLerpB = numStripUV.y + tmpLerpB;

    float tmpLerpAlpha = clamp(abs(clamp(tmpU, -10, 0)) - 1, 0, 10);
    tmpLerpAlpha = ceil(tmpLerpAlpha);
    tmpLerpAlpha = clamp(tmpLerpAlpha, 0, 1);

    float decimalSymbolMask = (1 - SphereMask(tmpU.x, -0.5, 0.5)) * (tmpLerpAlpha + tmpSymMaskB);

    float tmpLerpA = numStripUV.y + floor(frac(absValue / pow(10, ceilU + 1)) * 100) / 10;
    float tmpLerp = lerp(tmpLerpA, tmpLerpB, tmpLerpAlpha);

    //
    float4 numColor = tex2D(numberStripTex, float2(-tmpFrac, -tmpLerp));
    float finalColor = (numColor * decimalSymbolMask + decimalColor + symbolColor) * cropMask;
    finalColor = clamp(finalColor, 0, 1);

    return finalColor;
}


#define SD_TEX_DECLARE(numSpripTex, numPeriodTex)	sampler2D numSpripTex; \
                                                    float4 numSpripTex##_ST; \
                                                    sampler2D numPeriodTex; \
                                                    float4 numPeriodTex##_ST;


#define SD_TEX_UV(outputUV, inputUV) outputUV = TRANSFORM_TEX(inputUV, _DebugNumberStripTex);



#define DEBUG(uv, val) \
    return DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv, val);


#define DEBUG2(uv, val) \
    float r = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv, val.x); \
    float g = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, 0.2) , val.y); \
    return float4(r, g, 0, 0);

#define DEBUG3(uv, val) \
    float r = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, -0.2), val.x); \
    float g = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv, val.y); \
    float b = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, 0.2) , val.z); \
    return float4(r, g, b, 0);

#define DEBUG4(uv, val) \
    float r = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, -0.3), val.x); \
    float g = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, -0.1) , val.y); \
    float b = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, 0.1) , val.z); \
    float a = DebugValue(_DebugNumberStripTex, _DebugNumberPeriodTex, 8, uv + float2(0, 0.3) , val.w); \
    return float4(r, g, b, 0) + a;


#endif // SHADER_DEBUG_INCLUDED
