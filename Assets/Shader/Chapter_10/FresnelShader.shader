Shader "Unity Shader book/Chapter10/FresnelShader"
{
    Properties
    {
        _Diffuse("diffuse",color) =( 1.0, 1.0, 1.0, 1.0)

        _FresnelScale("FresnelScale",range(0,1)) = 0.5 //菲涅尔整体缩放因子，本文都喜欢给各个效果加上一个独立的因子控制
        _Bias("fresnel bias",float)  = 1.0
        _Scale("fresnel scale",float) = 1.0
        _Power("fresnel power",float) = 1.0

        _CubeMap ("cube map", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            "LightMode"="ForwardBase"
            }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            // make fog work


            #include "UnityCG.cginc"
            #include "UnityLightingcommon.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 worldPos : TEXCOORD0;

                float3 worldNormal:TEXCOORD1;
                float3 worldViewDir :TEXCOORD2;
                float3 worldLightDir:TEXCOORD3;

                float3 worldReflctionDir:TEXCOORD4;
            };

            samplerCUBE _CubeMap;

            float4 _Diffuse;
            float _FresnelScale;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //逆转矩阵
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                o.worldLightDir = UnityWorldSpaceLightDir(o.worldPos);
                o.worldViewDir  = UnityWorldSpaceViewDir(o.worldPos);

                o.worldReflctionDir = reflect(-normalize( o.worldViewDir ), normalize(o.worldNormal) );

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 normalDir = normalize(i.worldNormal);

                fixed3 worldPos = normalize(i.worldPos);
                fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 worldLightDir = normalize(i.worldLightDir);

                fixed3 reflection = texCUBE(_CubeMap,i.worldReflctionDir).xyz * _Diffuse.xyz;
                fixed3 fresnel = _FresnelScale + (1- _FresnelScale) * pow(1-dot( worldViewDir, normalDir ),5);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.xyz * _Diffuse.xyz * saturate(dot( worldLightDir, normalDir));

                fixed3 color = ambient + lerp(diffuse,reflection, saturate(fresnel));
                // fixed3 color = ambient +  diffuse + reflection * fresnel;


                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
