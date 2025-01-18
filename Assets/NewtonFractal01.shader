Shader "Custom/ModularFractalShader_BStyle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // NewtonFractal 原有属性
        _CenterX  ("Center X", Float) = 10000
        _CenterY  ("Center Y", Float) = 10000
        _Scale    ("Scale",    Float) = 1
        _FlowLight("FlowLight", Range(-3,3)) = 1
        _CX       ("CX", Float) = 1
        _CY       ("CY", Float) = 1
        [Toggle]_UseJulia ("Enable Julia", Float) = 0
        _Iterations ("Iterations", Float) = 500
        [HDR]_Color  ("_Color", Color) = (10.0, 2.5, 0.75, 1)
        [Toggle]_Reverse ("Enable Reverse", Float) = 0
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

            //////////////////////////////////////////////////////////////
            // B 中使用的帮助函数 & 常量
            //////////////////////////////////////////////////////////////

            // 为了演示，让 FlowLight 作为 leafOrbitOffset
            // 若你想让 orbitTrapInfluence, colorOffset 等也可调,
            // 可以再加到 Properties。
            static const float  bound       = 32.0;
            static const float  smoothOffset= -1.0 - log2(log2(bound));

            // "Triangular" orbit trap
            float triangleOrbit(float2 p)
            {
                p.y = abs(p.y);
                return max(-p.x, dot(p, float2(0.5, 0.5 * sqrt(3.0))));
            }

            // "Leaf" orbit trap
            float leafOrbit(float2 p, float offset)
            {
                p.y = abs(p.y);
                p.y += offset;
                float leafDist = length(p) - offset;
                return leafDist;
            }

            // 复数乘法
            float2 complexMultiply(float2 c1, float2 c2)
            {
                return float2(
                    c1.x*c2.x - c1.y*c2.y,
                    c1.x*c2.y + c1.y*c2.x
                );
            }

            // B 中的 colorBand：对三通道分别做 (0.5 - 0.5cos(phase))^exponents
            float3 colorBand(float t, float3 exponents)
            {
                float phase = t * UNITY_TWO_PI;
                // pow((X).xxx, exponents) => 每个通道做 X^(exponents[ch])
                return pow( (0.5 - 0.5*cos(phase)).xxx, exponents );
            }

            //////////////////////////////////////////////////////////////
            // NewtonFractal 原有的函数 & 迭代
            //////////////////////////////////////////////////////////////
            float4 _Color;         // 原本作为最终色，这里可当做“基底”或不用
            float  _CenterX;
            float  _CenterY;
            float  _Scale;
            float  _FlowLight;     // 相当于B中的 leafOrbitOffset
            float  _CX;
            float  _CY;
            float  _Reverse;
            float  _Iterations;
            float  _UseJulia;

            // A 中的 func & deriv
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

                float realPart = sinh(x)*cos(y) - sin(x)*cosh(y);
                float imagPart = cosh(x)*sin(y) - cos(x)*sinh(y);

                return float2(realPart, imagPart);
            }

            void newtonIteration(inout float2 z)
            {
                float2 fz  = func(z);
                float2 dfz = deriv(z);

                float denom    = dot(dfz, dfz);
                float realPart = fz.x*dfz.x + fz.y*dfz.y;
                float imagPart = -fz.x*dfz.y + fz.y*dfz.x;

                z.x -= realPart / denom;
                z.y -= imagPart / denom;
            }

            //////////////////////////////////////////////////////////////
            // 把 B 的 OrbitTrap + In/Out 逻辑融合进 Newton 迭代
            //////////////////////////////////////////////////////////////

            float3 calculateFractalColorBStyle(float2 c, float maxIters)
            {
                // 保留 Reverse 逻辑
                if (_Reverse > 0.5f)
                {
                    float denom = dot(c,c);
                    if (denom > 1e-14) c /= denom;
                }

                // 如果要 Julia，就替换 c
                float2 juliaConst = 0;
                if (_UseJulia > 0.5f)
                    juliaConst = float2(_CX * 0.00001, _CY * 0.00001);

                // 准备轨道陷阱(orbitTrap)相关变量
                float outerDist = 1e5;
                float innerDist = 1e5;

                float2 z = c;  // 当前迭代 z
                float iTime = _Time.y; // 用于颜色动画(可注释)

                // 这里额外定义一个“是否收敛”的标志
                bool converged = false;

                // 在 B 中：maxIters=600, bound=32, ...
                // 在这里我们用传入的 maxIters 做循环
                float iterIdx = 0.0;

                for (float i = 0; i < maxIters; i++)
                {
                    // Newton 迭代
                    float2 prev = z;
                    newtonIteration(z);
                    // 如果是 Julia 模式，严格来说 A 并没有把 z^2 + cJulia 这样的运算写在 newtonIteration 里；
                    // 这里保持你的A原逻辑: newtonIteration并不关心Julia常量
                    // => 也就是 “_UseJulia” 在Newton公式中并不改变 z 的更新方式，而是只改变了 C? 
                    // 所以可视需要决定是否把 (z += juliaConst) 或之类操作加进来……(示例先不做)
                    
                    // 额外：更新 orbitTrap
                    {
                        // leafOrbit( 5.0 * z ), 这里用 _FlowLight 作为 leafOrbitOffset
                        float leaf = leafOrbit(5.0f * z, _FlowLight);
                        float valLeaf = log( 0.4f * abs( log(max(1e-10, abs( log(max(1e-10, leaf)))))) + 0.04f );
                        outerDist = min(outerDist, valLeaf);

                        float tri = triangleOrbit(z);
                        innerDist = min(innerDist, tri);
                    }

                    // 判断收敛
                    float2 val = func(z);
                    if (length(val) < 1e-6)
                    {
                        // 提前收敛 => “In-Set”
                        converged = true;
                        iterIdx = i; // 记录迭代次数
                        break;
                    }

                    // 也可以加一个防止爆掉的检测(若 z 特别大)
                    float zz = dot(z,z);
                    if (zz>1e8)
                    {
                        // 说明 z 爆炸式增大 => 也算不收敛, 直接退出
                        converged = false;
                        iterIdx = i;
                        break;
                    }

                    // 若都没有 break, 最终i会到 maxIters-1
                    iterIdx = i;
                }

                // 根据“是否在迭代内收敛”判断  In-Set or Out-Set
                // B 中 InSet => iters == maxIters(没爆), OutSet => break  (爆) 
                // Newton 中正好相反: 迭代中提前 break => in-set, 否则 out-set
                float3 finalColor = 0;

                if (converged && iterIdx < maxIters)
                {
                    // ---------- In-Set 着色 ----------
                    // B 中： t = 300.0 * innerDist - 0.075 * iTime + 0.45
                    float t = 300.0 * innerDist - 0.075f * iTime + 0.45f;
                    // 通道指数用 B 的 inSet: (6,20,1.5) 也可换成你想要的
                    finalColor = colorBand(t, float3(6.0, 20.0, 1.5));
                    // 需要外边渲染就注释
                    finalColor = 0;
                }
                else
                {
                    // ---------- Out-Set 着色 ----------
                    // 先做 B 式 smooth iteration count:
                    // smoothIters = iterIdx - (log2(log2(zz)) + smoothOffset)
                    // 这里 zz=|z|^2, 取最后一次 z
                    float zz = max(dot(z,z), 1.000001f); // 防止 <1 出现负数
                    float smoothIters = iterIdx - (log2(log2(zz)) + smoothOffset);

                    // B 中: t = -0.25*orbitTrapInfluence * outerDist + 0.9*log2(smoothIters)
                    //               + 0.5*(1.0-orbitTrapInfluence) + colorOffset
                    // 这里简化 orbitTrapInfluence=1.0, colorOffset=0
                    float orbitTrapInfluence = 1.0;
                    float colorOffset = 0.0;
                    float t = -0.25f*orbitTrapInfluence*outerDist
                              + 0.9f*log2(smoothIters)
                              + 0.5f*(1.0f - orbitTrapInfluence)
                              + colorOffset;

                    // B 中 outSet 的通道指数: (10, 2.5, 0.75) 
                    finalColor = colorBand(t, float3(10.0, 2.5, 0.75));
                }

                return finalColor;
            }

            //////////////////////////////////////////////////////////////
            // 顶点/片元主流程
            //////////////////////////////////////////////////////////////
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv     : TEXCOORD0;
            };
            float4 frag(v2f i) : SV_Target
            {
                // 与 A 一样：把 UV 映射到 -1..1，再乘以 _Scale * 0.00001
                float2 uv = i.uv * 2.0 - 1.0;
                uv *= _Scale * 0.00001;

                // 计算当前像素在复平面上的初始坐标
                float2 C = float2(_CenterX, _CenterY) + uv;

                // 用我们融合了 B 着色的函数来得到结果
                float3 color = calculateFractalColorBStyle(C, _Iterations);

                return float4(color, 1.0);
            }

            ENDCG
        }
    }
}
