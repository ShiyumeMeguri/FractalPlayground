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

            //////////////////////////////////////////////////////////////////////////
            // 变量定义
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
            // 实用函数
            float3 colorBand(float t, float3 exponents)
            {
                float phase = t * UNITY_TWO_PI;
                return pow((0.5f - (0.5f * cos(phase))).xxx, exponents);
            }

            float2 func(float2 pos)
            {
                float x = pos.x;
                float y = pos.y;

                float coshX = cosh(x);
                float sinhX = sinh(x);
                float cosY  = cos(y);
                float sinY  = sin(y);

                float cosX  = cos(x);
                float sinX  = sin(x);
                float coshY = cosh(y);
                float sinhY = sinh(y);

                float realPart = coshX * cosY + cosX * coshY - 1.0;
                float imagPart = sinhX * sinY - sinX * sinhY;

                return float2(realPart, imagPart);
            }

            float2 deriv(float2 pos)
            {
                float x = pos.x;
                float y = pos.y;

                float realPart = sinh(x) * cos(y) - sin(x) * cosh(y);
                float imagPart = cosh(x) * sin(y) - cos(x) * sinh(y);

                return float2(realPart, imagPart);
            }

            void newtonIteration(inout float2 z)
            {
                float2 fz  = func(z);
                float2 dfz = deriv(z);

                float denom = dot(dfz, dfz);
                float realPart = fz.x * dfz.x + fz.y * dfz.y;
                float imagPart = -fz.x * dfz.y + fz.y * dfz.x;

                z.x -= realPart / denom;
                z.y -= imagPart / denom;
            }

            //////////////////////////////////////////////////////////////////////////
            // 修改后的迭代计算函数
            float computeNewtonIters(float2 z, float maxIterations, out float totalChange)
            {
                float count = 0.0;
                totalChange = 0.0;

                for (float i = 0.0; i < maxIterations; i++)
                {
                    float2 prevZ = z;

                    newtonIteration(z);

                    // 记录每次迭代的变化量
                    float change = length(z - prevZ);
                    totalChange += change;

                    float2 val = func(z);
                    if (length(val) < 1e-6)
                    {
                        break;
                    }
                    count = i;
                }

                return count;
            }

            //////////////////////////////////////////////////////////////////////////
            // 修改后的颜色计算函数
            float3 calculateFractalColor(float2 C, float maxIterations)
            {
                if (_Reverse != 0.0)
                {
                    float denom = C.x * C.x + C.y * C.y;
                    if (denom != 0.0)
                    {
                        C /= denom;
                    }
                }

                float2 z = C;
                if (_UseJulia != 0.0)
                {
                    C = float2(_CX * 0.00001, _CY * 0.00001);
                }

                // 新增 totalChange 参数
                float totalChange;
                float iterCount = computeNewtonIters(z, maxIterations, totalChange);

                // 映射颜色
                float t = (0.9 * log2(iterCount + 1.0)) + 0.5f;

                // 用变化量调制颜色的亮度
                float brightness = saturate(log2(1.0 + totalChange));
                float3 baseColor = colorBand(t, _Color.rgb);
                return baseColor * brightness;
            }

            //////////////////////////////////////////////////////////////////////////
            // 主片元函数
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
