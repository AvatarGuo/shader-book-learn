Shader "Unity Shader book/Chapter8/Alpha test"
{
    Properties
    {
        _MainTex ("Texture", 2D)   = "white" {}
        _Diffuse("diffuse" ,color) = (1.0 , 1.0 , 1.0 , 1.0 )
        _CutOff("cutOff",Range(0,1)) = 0.5

        _Specular("specular",color) = ( 1.0, 1.0, 1.0, 1.0 )
        _Gloss("gloss",Range(20.0,240)) = 20.0
    }
    SubShader
    {
        Tags { 
                "RenderType"="TransParentCutout"
                "IgnoreProjector"="True"

                "Queue"= "AlphaTest"

         }
        LOD 100

        Pass
        {
            Tags {
                "LightMode"="ForwardBase"
            }


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed _CutOff;
            fixed4 _Diffuse;

            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal:Normal;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed3 worldNormal:TEXCOORD1;
                fixed3 worldPos:TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal    = UnityObjectToWorldNormal(v.normal);
                o.worldPos  = mul( unity_ObjectToWorld , v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 abedo = tex2D(_MainTex, i.uv);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo.xyz;


                clip(abedo.a - _CutOff);


                // fixed3 viewDir = UnityWorldSpaceViewDir(o.worldPos);

                fixed3 lightDir = normalize( UnityWorldSpaceLightDir(i.worldPos ) );
                fixed3 normal   = normalize( i.worldNormal );
                fixed3 viewDir  = normalize( UnityWorldSpaceViewDir(i.worldPos) );
                //没有法线贴图这里加个specular吧


                fixed3 diffuse = _Diffuse.xyz * abedo.xyz * _LightColor0.xyz * saturate(dot(lightDir,normal ));


                fixed3 halfVector = normalize( lightDir + viewDir );
                fixed3 specular   = _Specular.xyz * _LightColor0.xyz * pow(max(0 ,dot(normal ,halfVector)) ,_Gloss);

                fixed3 color = fixed3(ambient + diffuse + specular);
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
