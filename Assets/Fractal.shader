Shader "Custom/ModularFractalShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Enum(FractalType)]
        _FractalType ("Fractal Type", Float) = 0

        _CenterX ("Center X", Float) = 10000
        _CenterY ("Center Y", Float) = 10000
        _Scale   ("Scale",    Float) = 1
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
            // 引入所有分形函数
            #include "FractalFunction.hlsl"

            // 输入与属性
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4    _MainTex_ST;

            float4 _Color;
            float  _CenterX;
            float  _CenterY;
            float  _CX;
            float  _CY;
            float  _Reverse;
            float  _Scale;
            float  _FlowLight;
            float  _Iterations;
            float  _UseJulia;

            int    _FractalType; 

            float3 colorBand(float t, float3 exponents)
            {
                float phase = t * UNITY_TWO_PI;
                // 这里使用三通道相同的 (0.5 - 0.5*cos(phase))^exponents
                // pow((X).xxx, exponents) 相当于对每个通道做 X^exponents[channel]
                return pow((0.5f - (0.5f * cos(phase))).xxx, exponents);
            }

            // 计算平滑迭代次数
            float calculateSmoothIterations(float2 z, float2 c, float bound, float smoothOffset, float maxIterations)
            {
                float iters = 1.0f;
                float zz = 0.0f;
                for (; iters < maxIterations; iters++)
                {
                    // 使用我们从 Fractals.hlsl 引入的统一函数
                    z = applySelectedFractal(_FractalType, z, c);

                    zz = dot(z,z);
                    if (zz > bound)
                        break;
                }

                // 若到达最大迭代，返回 0 表示并未逃逸
                if (iters == maxIterations)
                    return 0.0f;

                // 光滑逃逸 (Smooth Escape)
                return iters - (log2(log2(zz)) + smoothOffset);
            }

            // 计算像素颜色
            float3 calculateFractalColor(float2 c, float maxIterations)
            {
                // 复制 B 中逻辑
                const float bound = 32.0;
                const float smoothOffset = -log2(log2(bound)) - 1.0;

                // Reverse 逻辑
                if (_Reverse > 0.5)
                {
                    float denom = c.x*c.x + c.y*c.y;
                    c /= denom;
                }

                // 依据 _UseJulia 判断是 Mandelbrot 还是 Julia
                float2 z = c; // 如果 UseJulia=0，则初始 z=c
                if (_UseJulia > 0.5)
                {
                    // 如果启用 Julia，则 c=(_CX, _CY) (此处乘以小系数仅演示效果)
                    c = float2(_CX * 0.00001, _CY * 0.00001);
                }

                // 进行迭代计算，得到平滑迭代次数
                float smoothIters = calculateSmoothIterations(z, c, bound, smoothOffset, maxIterations);

                // 将迭代次数映射到 [0,1]，再通过 colorBand 生成颜色
                float t = (0.9f * log2(smoothIters)) + 0.5f;
                return colorBand(t, _Color.rgb);
            }

            float4 frag(v2f i) : SV_Target
            {
                // 将 UV 范围转换到 -1..1
                float2 uv = i.uv * 2.0 - 1.0;
                // 缩放
                uv *= _Scale * 0.00001;

                // 得到复平面上的坐标
                float2 c = float2(_CenterX, _CenterY) + uv;

                // 计算颜色
                float3 color = calculateFractalColor(c, _Iterations);

                // 返回 RGBA
                return float4(color, 1.0f);
            }
            ENDCG
        }
    }
}
