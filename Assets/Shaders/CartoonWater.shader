Shader "Custom/CartoonWater_URP"
{
    Properties
    {
        _DeepColor("Deep Color", Color) = (0.105,0.31,0.63,1)
        _ShallowColor("Shallow Color", Color) = (0.275,0.78,1,1)
        _RimColor("Rim Color", Color) = (1,1,1,1)

        _WaveAmp("Wave Amp", Float) = 0.18
        _WaveLen("Wave Len", Float) = 6
        _WaveSpeed("Wave Speed", Float) = 1

        _WaveAmp1("Wave Amp1", Float) = 0.14
        _WaveLen1("Wave Len1", Float) = 5
        _WaveSpeed1("Wave Speed1", Float) = 1.2

        _WaveAmp2("Wave Amp2", Float) = 0.12
        _WaveLen2("Wave Len2", Float) = 8
        _WaveSpeed2("Wave Speed2", Float) = 0.8

        _RippleCenter("Ripple Center (XZ)", Vector) = (0,0,0,0)
        _RippleStrength("Ripple Strength", Float) = 0
        _RippleTime("Ripple Time", Float) = 0

        _QuantizeLevels("Quantize Levels", Float) = 3
        _FresnelPower("Fresnel Power", Float) = 3
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200
        Cull Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5

            // ------------ URP Includes ------------
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ------------ Variables ------------
            float4 _DeepColor, _ShallowColor, _RimColor;
            float _WaveAmp, _WaveLen, _WaveSpeed;
            float _WaveAmp1, _WaveLen1, _WaveSpeed1;
            float _WaveAmp2, _WaveLen2, _WaveSpeed2;
            float4 _RippleCenter;
            float _RippleStrength;
            float _RippleTime;
            float _QuantizeLevels;
            float _FresnelPower;

            // Replace static const → define (Unity 6 safe)
            #define TWO_PI 6.28318530718

            // ------------ Wave Functions ------------
            float directionalWave(float2 pos, float2 dir, float amp, float len, float speed, float t)
            {
                float k = TWO_PI / len;
                return sin(dot(pos, dir) * k + t * speed) * amp;
            }

            float rippleFunc(float2 pos, float2 center, float strength, float t)
            {
                float d = distance(pos, center);
                return sin(d * 12 - t * 4) * exp(-d * 2) * strength;
            }

            float totalDisplacement(float2 p, float t)
            {
                return  directionalWave(p, float2(1,0), _WaveAmp, _WaveLen, _WaveSpeed, t)
                      + directionalWave(p, float2(0.5,0.5), _WaveAmp1, _WaveLen1, _WaveSpeed1, t)
                      + directionalWave(p, float2(-1,0.3), _WaveAmp2, _WaveLen2, _WaveSpeed2, t)
                      + rippleFunc(p, _RippleCenter.xz, _RippleStrength, _RippleTime);
            }

            // ------------ Structs ------------
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            // ------------ Vertex Shader ------------
            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 posWS = TransformObjectToWorld(IN.positionOS);
                float2 posXZ = posWS.xz;

               float t = _Time.y;


                float h = totalDisplacement(posXZ, t);
                posWS.y += h;

                OUT.worldPos = posWS;
                OUT.positionCS = TransformWorldToHClip(posWS);

                float eps = 0.1;
                float dx = (totalDisplacement(posXZ + float2(eps,0), t) - totalDisplacement(posXZ - float2(eps,0), t)) / (2*eps);
                float dz = (totalDisplacement(posXZ + float2(0,eps), t) - totalDisplacement(posXZ - float2(0,eps), t)) / (2*eps);

                OUT.normalWS = normalize(TransformObjectToWorldDir(float3(-dx, 1, -dz)));
                OUT.uv = IN.uv;

                return OUT;
            }

            // ------------ Fragment Shader ------------
            half4 frag (Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight(); // Unity 6 URP lighting
                float3 L = normalize(mainLight.direction);
                float3 N = normalize(IN.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - IN.worldPos);

                float ndotl = saturate(dot(N, L));
                float band = floor(ndotl * _QuantizeLevels) / max(_QuantizeLevels - 1, 1);

                float depthMix = saturate(IN.worldPos.y * 0.5 + 0.2);
                float3 baseCol = lerp(_DeepColor.rgb, _ShallowColor.rgb, depthMix);

                float3 col = baseCol * (0.5 + 0.8 * band);

                float fres = pow(1 - saturate(dot(N, V)), _FresnelPower);
                col += _RimColor.rgb * fres * 0.25;

                return half4(col, 1);
            }

            ENDHLSL
        }
    }

    FallBack Off
}
