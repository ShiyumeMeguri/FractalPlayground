Shader "Custom/CustomShader"
{
    Properties
    {
        _Center ("Center", Vector) = (0.0, 0.0, 0.0, 0.0)
        _Zoom ("Zoom", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderQueue" = "Geometry" }

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

            static const float2 _214_value = float2(0.0f, 0.0f);
            static const float _214_lengtha = 2000.0f;
            static const int _214_step = 10;

            float4 _Center;
            float _Zoom;

            float2 coshComplex(float2 a)
            {
                return float2(cosh(a.x) * cos(a.y), sinh(a.x) * sin(a.y));
            }

            float2 cosComplex(float2 a)
            {
                return float2(cos(a.x) * cosh(a.y), -sin(a.x) * sinh(a.y));
            }

            float2 sinhComplex(float2 a)
            {
                return float2(sinh(a.x) * cos(a.y), cosh(a.x) * sin(a.y));
            }

            float2 sinComplex(float2 a)
            {
                return float2(sin(a.x) * cosh(a.y), cos(a.x) * sinh(a.y));
            }

            float2 complexDivide(float2 a, float2 b)
            {
                float d = dot(b, b);
                return float2(dot(a, b), a.y * b.x - a.x * b.y) / d;
            }

            void foldApproach(float2 v, out float lengtha, out int step, out float2 value)
            {
                for (int i = 0; i < 100; i++)
                {
                    float2 pNext = coshComplex(v) + cosComplex(v) - float2(1.0f, 0.0f);
                    float2 pDiff = sinhComplex(v) - sinComplex(v);
                    float2 vNext = v - complexDivide(pNext, pDiff);
                    if (distance(vNext, v) < 0.001f)
                    {
                        lengtha = length(vNext);
                        step = i;
                        value = vNext;
                        return;
                    }
                    v = vNext;
                }
                lengtha = _214_lengtha;
                step = _214_step;
                value = _214_value;
            }

            float4 frag(v2f i) : SV_Target
            {
                // 平移UV不缩放，防止分形变形
                float2 uv = (i.uv - 0.5) / _Zoom + _Center.xy;

                float lengtha, step;
                float2 value;
                foldApproach(uv, lengtha, step, value );
                float c = frac(step / 20.0f);
                float4 color = float4(frac(c * c * 0.8f), frac(c * c * 0.8f), 0.0f, 1.0f);
                color.rgb = color.zxy;
                return color;
            }

            ENDCG
        }
    }
}
