Shader "Custom/ModularFractalShader_BStyle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(FractalType)] _FractalType ("Fractal Type", Float) = 0
        _CenterX ("Center X", Float) = 10000
        _CenterY ("Center Y", Float) = 10000
        _Scale   ("Scale", Float) = 1
        leafOrbitOffset ("Leaf Orbit Offset", Range(-3,3)) = 1
        _CX ("CX", Float) = 1
        _CY ("CY", Float) = 1
        [Toggle]_UseJulia ("Enable Julia", Float) = 0
        _Iterations ("Iterations", Float) = 500
        [HDR]_Color ("Base Color (HSV Base)", Color) = (10.0, 2.5, 0.75, 1)
        [Toggle]_Reverse ("Enable Reverse", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Cull Back
            ZWrite On
            ZTest LEqual
            Blend Off

            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #pragma target 4.0

            #include "UnityCG.cginc"
            #include "FractalFunction.hlsl"

            float2 complexMultiply(float2 c1, float2 c2)
            {
                return float2(
                    c1.x * c2.x - c1.y * c2.y,
                    c1.x * c2.y + c1.y * c2.x
                );
            }

            float triangleOrbit(float2 p)
            {
                p.y = abs(p.y);
                return max(-p.x, dot(p, float2(0.5, 0.5 * sqrt(3.0))));
            }

            float leafOrbit(float2 p, float offset)
            {
                p.y = abs(p.y) + offset;
                return length(p) - offset;
            }

            float3 colorBand(float t, float3 exponents)
            {
                float phase = t * UNITY_TWO_PI;
                return pow((0.5 - 0.5 * cos(phase)).xxx, exponents);
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _CenterX, _CenterY, _Scale;
            float leafOrbitOffset, _CX, _CY, _Reverse, _Iterations, _UseJulia;
            int _FractalType;

            float3 calculateFractalColorBStyle(float2 c, float maxIters)
            {
                if (_Reverse > 0.5)
                {
                    float denom = c.x * c.x + c.y * c.y;
                    c /= denom;
                }

                float2 z = c;
                float2 cJulia = (_UseJulia > 0.5) ? float2(_CX * 0.00001, _CY * 0.00001) : c;
                float outerDist = 1e5, innerDist = 1e5, iters = 1.0;
                const float boundSqr = 1024.0, smoothOff = -log2(log2(32.0)) - 1.0;

                for (; iters < maxIters; iters++)
                {
                    z = applySelectedFractal(_FractalType, z, cJulia);
                    float zz = dot(z, z);
                    if (zz > boundSqr) break;
                    outerDist = min(outerDist, log(0.4 * abs(log(max(1e-10, abs(log(max(1e-10, leafOrbit(5.0 * z, leafOrbitOffset))))))) + 0.04));
                    innerDist = min(innerDist, triangleOrbit(z));
                }

                float iTime = _Time.y;
                if (iters == maxIters)
                {
                    float t = 300.0 * innerDist - 0.075 * iTime + 0.45;
                    return colorBand(t, _Color.rgb);
                }
                else
                {
                    float smoothIters = iters - (log2(log2(dot(z, z))) + smoothOff);
                    float t = -0.25 * outerDist + 0.9 * log2(smoothIters) + 0.5;
                    return colorBand(t, _Color.rgb);
                }
            }

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = (i.uv * 2.0 - 1.0) * (_Scale * 0.00001);
                float2 c = float2(_CenterX, _CenterY) + uv;
                float3 color = calculateFractalColorBStyle(c, _Iterations);
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
