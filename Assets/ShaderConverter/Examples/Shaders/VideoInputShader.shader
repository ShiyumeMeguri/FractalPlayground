// https://www.shadertoy.com/view/Xdl3D8
// The MIT License
// Copyright © 2013 Javier Meseguer
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// This shader is converted by ShaderConverter : 
// https://u3d.as/2Zim 


Shader "Custom/VideoInputShader"
{
    Properties
    {
        _iMouse ("_iMouse", Vector) = (0,0,0,0)
        _MainTex ("_MainTex / iChannel0", 2D) = "black" {}
        //To Add Properties
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
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 4.0

            #include "UnityCG.cginc"

            //////////////////////////////////////////////////////////////////////////

            //Vertex Shader Begin
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            //Vertex Shader End

            //////////////////////////////////////////////////////////////////////////
            
            uniform float4 _iMouse;
            Texture2D<float4> _MainTex : register(t2);
            SamplerState sampler_MainTex : register(s2);

            static float4 gl_FragCoord;
            static float4 fragColor;

            struct SPIRV_Cross_Input
            {
                float4 gl_FragCoord : SV_Position;
            };

            struct SPIRV_Cross_Output
            {
                float4 fragColor : SV_Target0;
            };

            static float2 uv = 0.0f.xx;

            float rand(float2 co)
            {
                return frac(sin(dot(co, float2(12.98980045318603515625f, 78.233001708984375f))) * 43758.546875f);
            }

            float rand(float c)
            {
                float2 param = float2(c, 1.0f);
                return rand(param);
            }

            float randomLine(float seed)
            {
                float param = seed;
                float b = 0.00999999977648258209228515625f * rand(param);
                float param_1 = seed + 1.0f;
                float a = rand(param_1);
                float param_2 = seed + 2.0f;
                float c = rand(param_2) - 0.5f;
                float param_3 = seed + 3.0f;
                float mu = rand(param_3);
                float l = 1.0f;
                if (mu > 0.20000000298023223876953125f)
                {
                    l = pow(abs(((a * uv.x) + (b * uv.y)) + c), 0.125f);
                }
                else
                {
                    l = 2.0f - pow(abs(((a * uv.x) + (b * uv.y)) + c), 0.125f);
                }
                return lerp(0.5f, 1.0f, l);
            }

            float randomBlotch(float seed)
            {
                float param = seed;
                float x = rand(param);
                float param_1 = seed + 1.0f;
                float y = rand(param_1);
                float param_2 = seed + 2.0f;
                float s = 0.00999999977648258209228515625f * rand(param_2);
                float2 p = float2(x, y) - uv;
                p.x *= (_ScreenParams.x / _ScreenParams.y);
                float a = atan2(p.y, p.x);
                float v = 1.0f;
                float ss = (s * s) * ((sin((6.283100128173828125f * a) * x) * 0.100000001490116119384765625f) + 1.0f);
                if (dot(p, p) < ss)
                {
                    v = 0.20000000298023223876953125f;
                }
                else
                {
                    v = pow(dot(p, p) - ss, 0.0625f);
                }
                return lerp(0.300000011920928955078125f + (0.20000000298023223876953125f * (1.0f - (s / 0.0199999995529651641845703125f))), 1.0f, v);
            }

            void frag_main()
            {
                uv = gl_FragCoord.xy / _ScreenParams.xy;
                if (_iMouse.z < 0.89999997615814208984375f)
                {
                    float t = float(int(_Time.y * 15.0f));
                    float param = t;
                    float param_1 = t + 23.0f;
                    float2 suv = uv + (float2(rand(param), rand(param_1)) * 0.00200000009499490261077880859375f);
                    float3 image = _MainTex.Sample(sampler_MainTex, float2(suv.x, suv.y)).xyz;
                    float luma = dot(float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f), image);
                    float3 oldImage = 0.699999988079071044921875f.xxx * luma;
                    float vI = 16.0f * (((uv.x * (1.0f - uv.x)) * uv.y) * (1.0f - uv.y));
                    float param_2 = t + 0.5f;
                    vI *= lerp(0.699999988079071044921875f, 1.0f, rand(param_2));
                    float param_3 = t + 8.0f;
                    vI += (1.0f + (0.4000000059604644775390625f * rand(param_3)));
                    vI *= pow((((16.0f * uv.x) * (1.0f - uv.x)) * uv.y) * (1.0f - uv.y), 0.4000000059604644775390625f);
                    float param_4 = t + 7.0f;
                    int l = int(8.0f * rand(param_4));
                    if (0 < l)
                    {
                        float param_5 = (t + 6.0f) + 0.0f;
                        vI *= randomLine(param_5);
                    }
                    if (1 < l)
                    {
                        float param_6 = (t + 6.0f) + 17.0f;
                        vI *= randomLine(param_6);
                    }
                    if (2 < l)
                    {
                        float param_7 = (t + 6.0f) + 34.0f;
                        vI *= randomLine(param_7);
                    }
                    if (3 < l)
                    {
                        float param_8 = (t + 6.0f) + 51.0f;
                        vI *= randomLine(param_8);
                    }
                    if (4 < l)
                    {
                        float param_9 = (t + 6.0f) + 68.0f;
                        vI *= randomLine(param_9);
                    }
                    if (5 < l)
                    {
                        float param_10 = (t + 6.0f) + 85.0f;
                        vI *= randomLine(param_10);
                    }
                    if (6 < l)
                    {
                        float param_11 = (t + 6.0f) + 102.0f;
                        vI *= randomLine(param_11);
                    }
                    if (7 < l)
                    {
                        float param_12 = (t + 6.0f) + 119.0f;
                        vI *= randomLine(param_12);
                    }
                    float param_13 = t + 18.0f;
                    int s = int(max((8.0f * rand(param_13)) - 2.0f, 0.0f));
                    if (0 < s)
                    {
                        float param_14 = (t + 6.0f) + 0.0f;
                        vI *= randomBlotch(param_14);
                    }
                    if (1 < s)
                    {
                        float param_15 = (t + 6.0f) + 19.0f;
                        vI *= randomBlotch(param_15);
                    }
                    if (2 < s)
                    {
                        float param_16 = (t + 6.0f) + 38.0f;
                        vI *= randomBlotch(param_16);
                    }
                    if (3 < s)
                    {
                        float param_17 = (t + 6.0f) + 57.0f;
                        vI *= randomBlotch(param_17);
                    }
                    if (4 < s)
                    {
                        float param_18 = (t + 6.0f) + 76.0f;
                        vI *= randomBlotch(param_18);
                    }
                    if (5 < s)
                    {
                        float param_19 = (t + 6.0f) + 95.0f;
                        vI *= randomBlotch(param_19);
                    }
                    float3 _508 = oldImage * vI;
                    fragColor.x = _508.x;
                    fragColor.y = _508.y;
                    fragColor.z = _508.z;
                    float2 param_20 = uv + (t * 0.00999999977648258209228515625f).xx;
                    float4 _527 = fragColor;
                    float3 _529 = _527.xyz * (1.0f + ((rand(param_20) - 0.20000000298023223876953125f) * 0.1500000059604644775390625f));
                    fragColor.x = _529.x;
                    fragColor.y = _529.y;
                    fragColor.z = _529.z;
                }
                else
                {
                    fragColor = _MainTex.Sample(sampler_MainTex, uv);
                }
            }

            SPIRV_Cross_Output frag(SPIRV_Cross_Input stage_input)
            {
                gl_FragCoord = stage_input.gl_FragCoord;
                gl_FragCoord.w = 1.0 / gl_FragCoord.w;
                frag_main();
                SPIRV_Cross_Output stage_output;
                stage_output.fragColor = fragColor;
                return stage_output;
            }


            ENDCG
        }
    }
}