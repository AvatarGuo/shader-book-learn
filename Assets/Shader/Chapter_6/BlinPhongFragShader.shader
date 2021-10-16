Shader "Unity Shader book/Chapter6/blinn-phong fragment Shader"
{
    Properties
    {
        _Diffuse("diffuse",color) = (1.0,1.0,1.0,1.0)

        //specular
        _Specular("specular",color) = (1.0,1.0,1.0,1.0)
        _Gloss("gloss",Range(8.0,256)) = 20
    }

    SubShader
    {
        Tags{ 
                "RenderType"="Opaque"
                "LightMode"="ForwardBase"
            }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 position:SV_POSITION;
                fixed3 normal:normal;

                fixed3 positionWrold:TEXCOORD0;

            };

            //
            fixed4 _Diffuse;

            float _Gloss;
            fixed4 _Specular;


            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);

                o.normal = mul(v.normal,(fixed3x3)unity_WorldToObject);
                o.positionWrold = mul(unity_ObjectToWorld,v.vertex);

               return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //环境光
                fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //漫反射
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 normal = normalize(i.normal);

                //光颜色
                fixed3 lightColor = _LightColor0.xyz;
                //diffuse 
                fixed3 diffuse = lightColor * _Diffuse.xyz * saturate( dot( lightDir , normal ) );

                //计算specular 
                fixed3 viewDir = normalize ( _WorldSpaceCameraPos.xyz - i.positionWrold.xyz);
                fixed3 halfVector = normalize(viewDir + lightDir);

                //blin-phong 改进模型
                // fixed3 reflectDir = normalize( reflect(-lightDir , normal ) );
                fixed3 specular = lightColor * _Specular.xyz * pow(saturate( dot( halfVector , normal )) , _Gloss );
                fixed3 color = ambient + diffuse + specular  ;

                //
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
