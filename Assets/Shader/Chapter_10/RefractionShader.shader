Shader "Unity Shader book/Chapter10/RefractionShader"
{
    Properties
    {

        _Color("Color tint",color) = (1.0,1.0,1.0,1.0)
        _RefractionColor("refraction color",color) = (1.0,1.0,1.0,1.0)
        _RefractionRatio("refraction ratio",range(0,1)) = 0.5
        _RefractionAmount("refraction amount",range(0,1.0)) = 0.5 
        _CubeMap("cube map",Cube) = "_Skybox" {}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {

            Tags{
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;

                float3 worldViewDir:TEXCOORD2; //在cubemap上的采样方向 ，反射方向
                float3 worldRefract:TEXCOORD3; // 折射方向
            };

            samplerCUBE _CubeMap;
            float4 _Color;
            float4 _RefractionColor ;
            float _RefractionRatio;
            float _RefractionAmount;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldViewDir =  UnityWorldSpaceViewDir(o.worldPos) ;

                o.worldRefract = refract(-normalize( o.worldViewDir ) ,normalize(o.worldNormal),_RefractionRatio);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 viewDir = normalize( i.worldViewDir);
                fixed3 normal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.xyz * _Color.xyz * max(0,dot(normal,lightDir));

                fixed3 refraction = texCUBE(_CubeMap , i.worldRefract).xyz * _RefractionColor;
                fixed3 color = ambient + lerp(diffuse,refraction,_RefractionAmount);


                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
