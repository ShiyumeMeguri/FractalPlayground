Shader "Custom/ModularFractalShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CenterX ("Center X", Float) = 10000
        _CenterY ("Center Y", Float) = 10000
        _Scale ("Scale", Float) = 1
        _FlowLight ("FlowLight", Range(-3,3)) = 1
        _CX ("CX", Float) = 1
        _CY ("CY", Float) = 1
        [Toggle]_UseJulia ("Enable Julia", Float) = 0
        _Iterations ("Iterations", Float) = 500
        [HDR]_Color ("_Color", Color) = (10.0, 2.5, 0.75, 1)
        [Toggle]_Reverse ("Enable Reverse", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderQueue" = "Geometry"}

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

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float _CenterX;
            float _CenterY;
            float _CX;
            float _CY;
            float _Reverse;
            float _Scale;
            float _FlowLight;
            float _Iterations;
            float _UseJulia;

            //////////////////////////////////////////////////////////////////////////

            // Utility Functions
            float2 complexMultiply(float2 c1, float2 c2)
            {
                return float2((c1.x * c2.x) - (c1.y * c2.y), (c1.x * c2.y) + (c1.y * c2.x));
            }

            float3 colorBand(float t, float3 exponents)
            {
                float phase = t * UNITY_TWO_PI;
                return pow((0.5f - (0.5f * cos(phase))).xxx, exponents);
            }

            //////////////////////////////////////////////////////////////////////////

            float2 applyFractalTransform(float2 z, float2 C)
            {
                return complexMultiply(z, z) + C;
            }

            float calculateSmoothIterations(float2 z, float2 C, float bound, float smoothOffset, float maxIterations)
            {
                float iters = 1.0f;
                float zz = 0.0f;
                for (; iters < maxIterations; iters++)
                {
                    z = applyFractalTransform(z, C);
                    zz = dot(z, z);
                    if (zz > bound)
                        break;
                }

                if (iters == maxIterations)
                    return 0.0f;

                return iters - (log2(log2(zz)) + smoothOffset);
            }

            float3 calculateFractalColor(float2 C, float maxIterations)
            {
                const float bound = 32.0;
                const float smoothOffset = -log2(log2(bound)) - 1.0;

                if (_Reverse)
                {
                    float denom = C.x * C.x + C.y * C.y;
                    C /= denom;
                }

                float2 z = C;
                
                if (_UseJulia)
                {
                    C = float2(_CX * 0.00001, _CY * 0.00001);
                }

                float smoothIters = calculateSmoothIterations(z, C, bound, smoothOffset, maxIterations);

                float t = (0.9 * log2(smoothIters)) + 0.5f;
                return colorBand(t, _Color.rgb);
            }

            float4 frag(v2f stage_input) : SV_Target
            {
                float2 uv = stage_input.uv * 2.0 - 1.0;
                uv *= _Scale * 0.00001;
                float2 C = float2(_CenterX, _CenterY) + uv;

                float3 color = calculateFractalColor(C, _Iterations);

                return float4(color, 1.0f);
            }

            ENDCG
        }
    }
}
