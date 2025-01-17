// cosh(z) + cos(z) - 1
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
            // 2) 片元着色所需的变量
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
            // 3) B 原有的实用函数：示例中 colorBand(...) 着色函数依旧保留
            float3 colorBand(float t, float3 exponents)
            {
                // B 中常见的一种条带着色方式
                float phase = t * UNITY_TWO_PI;
                // (0.5 - 0.5*cos(phase)) ^ exponents
                return pow((0.5f - (0.5f * cos(phase))).xxx, exponents);
            }

            //////////////////////////////////////////////////////////////////////////
            // 4) A 的分形核心逻辑：func + deriv + newtonIteration

            // A.1  原函数 f(z)
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

            // A.2 f'(z)
            float2 deriv(float2 pos)
            {
                float x = pos.x;
                float y = pos.y;

                float realPart = sinh(x) * cos(y) - sin(x) * cosh(y);
                float imagPart = cosh(x) * sin(y) - cos(x) * sinh(y);

                return float2(realPart, imagPart);
            }

            // A.3 牛顿迭代一步
            void newtonIteration(inout float2 z)
            {
                float2 fz  = func(z);
                float2 dfz = deriv(z);

                float denom = dot(dfz, dfz);
                // 分子 real / imag
                float realPart = fz.x * dfz.x + fz.y * dfz.y;
                float imagPart = -fz.x * dfz.y + fz.y * dfz.x;

                z.x -= realPart / denom;
                z.y -= imagPart / denom;
            }

            //////////////////////////////////////////////////////////////////////////
            // 5) 用于替换 B 原有的“幂次逃逸”迭代逻辑：计算迭代次数
            float computeNewtonIters(float2 z, float maxIterations)
            {
                float count = 0.0;
                // 迭代上限
                for (float i = 0.0; i < maxIterations; i++)
                {
                    newtonIteration(z);

                    // 如果收敛到某个阈值，就可以退出（例如长度很小）
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
            // 6) 计算最终颜色：将原先的 colorBand 等流程保留，仅用牛顿迭代替换掉原 Mandelbrot/Julia 逻辑
            float3 calculateFractalColor(float2 C, float maxIterations)
            {
                // 保留 B 原有属性的干预
                if (_Reverse != 0.0)
                {
                    float denom = C.x * C.x + C.y * C.y;
                    if (denom != 0.0)
                    {
                        C /= denom;
                    }
                }
                
                // 根据 B 中 _UseJulia 的做法做一个简单处理
                // （可根据自己需求，决定是否忽略或更复杂的设定）
                float2 z = C;
                if (_UseJulia != 0.0)
                {
                    // 只是演示把 C 加工一下，这里使用了 _CX, _CY
                    // 具体可根据需求自己组合
                    C = float2(_CX * 0.00001, _CY * 0.00001);
                }

                // 这里调用牛顿迭代核心，得到迭代次数
                float iterCount = computeNewtonIters(z, maxIterations);

                // 下面保持 B 原有的条带着色流程不变
                // 让它根据迭代次数来做一个 phase 偏移
                float t = (0.9 * log2(iterCount + 1.0)) + 0.5f;
                // 使用 B 中已有的 colorBand(...)
                return colorBand(t, _Color.rgb);
            }

            //////////////////////////////////////////////////////////////////////////
            // 7) fragment 主函数：几乎不动，仅替换对 calculateFractalColor(...) 的调用
            float4 frag(v2f stage_input) : SV_Target
            {
                // B 原有的坐标变换
                float2 uv = stage_input.uv * 2.0 - 1.0;
                uv *= _Scale * 0.00001;

                // 得到屏幕坐标下的复数 C
                float2 C = float2(_CenterX, _CenterY) + uv;

                // 用新的牛顿迭代流程来算颜色
                float3 color = calculateFractalColor(C, _Iterations);

                return float4(color, 1.0f);
            }

            ENDCG
        }
    }
}
