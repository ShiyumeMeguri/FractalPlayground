Shader "Custom/ModularFractalShader_BStyle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // 分形类型
        [Enum(FractalType)]
        _FractalType ("Fractal Type", Float) = 0

        _CenterX ("Center X", Float) = 10000
        _CenterY ("Center Y", Float) = 10000
        _Scale   ("Scale",    Float) = 1

        // 与 B 相呼应的“叶子形变”参数
        leafOrbitOffset ("Leaf Orbit Offset", Range(-3,3)) = 1

        _CX ("CX", Float) = 1
        _CY ("CY", Float) = 1

        [Toggle]_UseJulia ("Enable Julia", Float) = 0
        _Iterations ("Iterations", Float) = 500

        // 这里依旧保留 _Color，但会在 B 风格着色里将其作为基底再做一定变换
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

            // 引入分形函数（你自己实现的 applySelectedFractal 等）
            #include "FractalFunction.hlsl"

            // -------------------------------------------------
            // B 中的一些辅助函数，这里做相应改写（语法从GLSL转到HLSL风格）
            // -------------------------------------------------

            // 复数乘法
            float2 complexMultiply(float2 c1, float2 c2)
            {
                return float2(
                    c1.x*c2.x - c1.y*c2.y,
                    c1.x*c2.y + c1.y*c2.x
                );
            }

            // Triangular orbit trap
            float triangleOrbit(float2 p)
            {
                p.y = abs(p.y);
                return max(-p.x, dot(p, float2(0.5, 0.5 * sqrt(3.0))));
            }

            // Leaf orbit trap
            float leafOrbit(float2 p, float offset)
            {
                p.y = abs(p.y);
                p.y += offset; // 类似 B 中 leafOrbitOffset
                return length(p) - offset;
            }

            // 颜色波动带
            float3 colorBand(float t, float3 exponents)
            {
                float phase = t * UNITY_TWO_PI;
                // 与 B 一样：(0.5 - 0.5*cos(phase))^{exponents}
                return pow((0.5 - 0.5*cos(phase)).xxx, exponents);
            }

            // rgb <-> hsv (与 B 大致类似)
            float3 rgb2hsv(float3 c)
            {
                float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
                float4 p = (c.b < c.g) ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
                float4 q = (p.x < c.r) ? float4(c.r, p.yzx) : float4(p.xyw, c.r);

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(
                    abs(q.z + (q.w - q.y)/(6.0*d + e)),
                    d / (q.x + e),
                    q.x
                );
            }

            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            // -------------------------------------------------
            // 传入的属性
            // -------------------------------------------------

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;           // 在 A 中原本的颜色属性 (R,G,B,A)
            float  _CenterX;
            float  _CenterY;
            float  _Scale;
            float  leafOrbitOffset;  // 叶子形状修饰
            float  _CX;
            float  _CY;
            float  _Reverse;
            float  _Iterations;
            float  _UseJulia;
            int    _FractalType;

            // -------------------------------------------------
            // 计算最终颜色的核心函数：用 B 的 OrbitTrap + in/out set 方案
            // -------------------------------------------------
            float3 calculateFractalColorBStyle(float2 c, float maxIters)
            {
                // 保持 A 中的 Reverse 逻辑
                if (_Reverse > 0.5)
                {
                    float denom = c.x*c.x + c.y*c.y;
                    c /= denom;
                }

                // 区分 Mandelbrot / Julia
                float2 z = c;
                float2 cJulia = c;
                if (_UseJulia > 0.5)
                {
                    // 与 A 相同：用 ( _CX*0.00001, _CY*0.00001 ) 做 Julia 常量
                    cJulia = float2(_CX * 0.00001, _CY * 0.00001);
                }

                // orbitTrap 变量
                float outerDist = 1e5;
                float innerDist = 1e5;

                float iters = 1.0;
                const float bound     = 32.0;
                const float boundSqr  = bound * bound;
                const float smoothOff = -log2(log2(bound)) - 1.0;

                float2 currentZ = z;

                for (; iters < maxIters; iters++)
                {
                    // 原 A 逻辑：applySelectedFractal
                    if (_UseJulia > 0.5)
                        currentZ = applySelectedFractal(_FractalType, currentZ, cJulia);
                    else
                        currentZ = applySelectedFractal(_FractalType, currentZ, c);

                    float zz = dot(currentZ, currentZ);
                    // 若逃逸，跳出
                    if (zz > boundSqr)
                        break;

                    // OrbitTrap 计算：和 B 一样
                    // 1) outerDist
                    //   B 中是 leafOrbit(5.0*z)，这里也保持一致
                    float leaf = leafOrbit(5.0 * currentZ, leafOrbitOffset);
                    //   B 中那一长串：log(0.4 * abs(log(abs(log(leaf)))) + 0.04)
                    //   注意要保证不能对0或负数做 log，所以加个 max
                    float valLeaf = log(0.4 * abs(log(max(1e-10, abs(log(max(1e-10, leaf)))))) + 0.04);
                    outerDist = min(outerDist, valLeaf);

                    // 2) innerDist
                    float tri = triangleOrbit(currentZ);
                    innerDist = min(innerDist, tri);
                }

                // 取用时间（跟 B 一样给着色加一点动态）
                float iTime = _Time.y;

                // 若 iters == maxIters，表示“在集合内部”
                if (iters == maxIters)
                {
                    // B 的 in-set 公式： t = 300.0 * innerDist - 0.075*iTime + 0.45
                    float t = 300.0 * innerDist - 0.075 * iTime + 0.45;

                    // 为了跟 B 一致，这里再对传进来的 _Color 做 HSV 变换，给它一点 hue 摆动
                    float3 baseRGB = _Color.rgb;
                    float3 hsv = rgb2hsv(baseRGB);
                    hsv.x = hsv.x + 0.1 * sin(iTime * 0.3);  // 在原 hue 附近小幅摆动
                    float3 finalRGB = hsv2rgb(hsv);
                    
                    // 需要外边渲染就注释
                    return 0;
                    return colorBand(t, finalRGB);
                }
                else
                {
                    // B 的 out-of-set 公式：
                    //   smoothIters = iters - (log2(log2(zz)) + smoothOff)
                    //   t = -0.25*orbitTrapInfluence*outerDist + 0.9*log2(smoothIters)
                    //       + 0.5*(1-orbitTrapInfluence) + colorOffset
                    //   其中 orbitTrapInfluence、colorOffset 在 B 里会跟鼠标或动画有关，
                    //   这里先简单写死 orbitTrapInfluence=1, colorOffset=0
                    float orbitTrapInfluence = 1.0;
                    float colorOffset = 0.0;

                    // 需要先算出当前最后一次 zz
                    //   （上面循环 break 后就没有 zz 了，只好再计算一下）
                    float2 zLast = currentZ;
                    float lastZZ = dot(zLast, zLast);
                    float smoothIters = iters - (log2(log2(lastZZ)) + smoothOff);

                    float t = -0.25 * orbitTrapInfluence * outerDist
                              + 0.9 * log2(smoothIters)
                              + 0.5 * (1.0 - orbitTrapInfluence)
                              + colorOffset;

                    // 同样，对 _Color 做 HSV 后加一点时间扰动
                    float3 baseRGB = _Color.rgb;
                    float3 hsv = rgb2hsv(baseRGB);
                    hsv.x = hsv.x + 0.1 * sin(iTime * 0.3);
                    float3 finalRGB = hsv2rgb(hsv);

                    return colorBand(t, finalRGB);
                }
            }

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv     : TEXCOORD0;
            };


            // 像素着色
            float4 frag(v2f i) : SV_Target
            {
                // 将 UV 变换到 -1~1
                float2 uv = i.uv * 2.0 - 1.0;
                // 再根据 _Scale 做缩放（并在这里演示把 fractal 放大很多）
                uv *= _Scale * 0.00001;

                // 得到复平面上的坐标
                float2 c = float2(_CenterX, _CenterY) + uv;

                // 用我们新的 B 风格函数来获取分形颜色
                float3 color = calculateFractalColorBStyle(c, _Iterations);

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
