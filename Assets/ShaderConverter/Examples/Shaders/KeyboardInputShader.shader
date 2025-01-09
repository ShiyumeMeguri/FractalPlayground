// Created by inigo quilez - iq/2013


// An example showing how to use the keyboard input.
//
// Row 0: contain the current state of the 256 keys. 
// Row 1: contains Keypress.
// Row 2: contains a toggle for every key.
//
// Texel positions correspond to ASCII codes. Press arrow keys to test.


// See also:
//
// Input - Keyboard    : https://www.shadertoy.com/view/lsXGzf
// Input - Microphone  : https://www.shadertoy.com/view/llSGDh
// Input - Mouse       : https://www.shadertoy.com/view/Mss3zH
// Input - Sound       : https://www.shadertoy.com/view/Xds3Rr
// Input - SoundCloud  : https://www.shadertoy.com/view/MsdGzn
// Input - Time        : https://www.shadertoy.com/view/lsXGz8
// Input - TimeDelta   : https://www.shadertoy.com/view/lsKGWV
// Inout - 3D Texture  : https://www.shadertoy.com/view/4llcR4


// This shader is converted by ShaderConverter : 
// https://u3d.as/2Zim 


Shader "Custom/KeyboardInputShader"
{
    Properties
    {
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
            
            Texture2D<float4> _MainTex : register(t1);
            SamplerState sampler_MainTex : register(s1);

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

            void frag_main()
            {
                float2 uv = ((-_ScreenParams.xy) + (gl_FragCoord.xy * 2.0f)) / _ScreenParams.y.xx;
                float3 col = 0.0f.xxx;
                col = lerp(col, float3(1.0f, 0.0f, 0.0f), ((1.0f - smoothstep(0.300000011920928955078125f, 0.310000002384185791015625f, length(uv - float2(-0.75f, 0.0f)))) * (0.300000011920928955078125f + (0.699999988079071044921875f * _MainTex.Load(int3(int2(37, 0), 0)).x))).xxx);
                col = lerp(col, float3(1.0f, 1.0f, 0.0f), ((1.0f - smoothstep(0.300000011920928955078125f, 0.310000002384185791015625f, length(uv - float2(0.0f, 0.5f)))) * (0.300000011920928955078125f + (0.699999988079071044921875f * _MainTex.Load(int3(int2(38, 0), 0)).x))).xxx);
                col = lerp(col, float3(0.0f, 1.0f, 0.0f), ((1.0f - smoothstep(0.300000011920928955078125f, 0.310000002384185791015625f, length(uv - float2(0.75f, 0.0f)))) * (0.300000011920928955078125f + (0.699999988079071044921875f * _MainTex.Load(int3(int2(39, 0), 0)).x))).xxx);
                col = lerp(col, float3(0.0f, 0.0f, 1.0f), ((1.0f - smoothstep(0.300000011920928955078125f, 0.310000002384185791015625f, length(uv - float2(0.0f, -0.5f)))) * (0.300000011920928955078125f + (0.699999988079071044921875f * _MainTex.Load(int3(int2(40, 0), 0)).x))).xxx);
                col = lerp(col, float3(1.0f, 0.0f, 0.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(-0.75f, 0.0f)) - 0.3499999940395355224609375f))) * _MainTex.Load(int3(int2(37, 1), 0)).x).xxx);
                col = lerp(col, float3(1.0f, 1.0f, 0.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(0.0f, 0.5f)) - 0.3499999940395355224609375f))) * _MainTex.Load(int3(int2(38, 1), 0)).x).xxx);
                col = lerp(col, float3(0.0f, 1.0f, 0.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(0.75f, 0.0f)) - 0.3499999940395355224609375f))) * _MainTex.Load(int3(int2(39, 1), 0)).x).xxx);
                col = lerp(col, float3(0.0f, 0.0f, 1.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(0.0f, -0.5f)) - 0.3499999940395355224609375f))) * _MainTex.Load(int3(int2(40, 1), 0)).x).xxx);
                col = lerp(col, float3(1.0f, 0.0f, 0.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(-0.75f, 0.0f)) - 0.300000011920928955078125f))) * _MainTex.Load(int3(int2(37, 2), 0)).x).xxx);
                col = lerp(col, float3(1.0f, 1.0f, 0.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(0.0f, 0.5f)) - 0.300000011920928955078125f))) * _MainTex.Load(int3(int2(38, 2), 0)).x).xxx);
                col = lerp(col, float3(0.0f, 1.0f, 0.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(0.75f, 0.0f)) - 0.300000011920928955078125f))) * _MainTex.Load(int3(int2(39, 2), 0)).x).xxx);
                col = lerp(col, float3(0.0f, 0.0f, 1.0f), ((1.0f - smoothstep(0.0f, 0.00999999977648258209228515625f, abs(length(uv - float2(0.0f, -0.5f)) - 0.300000011920928955078125f))) * _MainTex.Load(int3(int2(40, 2), 0)).x).xxx);
                fragColor = float4(col, 1.0f);
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