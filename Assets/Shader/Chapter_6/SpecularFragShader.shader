Shader "Unity Shader book/Chapter6/Specular fragment Shader"
{
    Properties
    {
        //diffuse
        _Diffuse("diffuse",color) = (1.0,1.0,1.0,1.0)

        //specular
        _Specular("specular",color) = (1.0,1.0,1.0,1.0)
        _Gloss("gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Tags { 
                "RenderType"="Opaque"
                "LightMode" = "ForwardBase"
             }

        LOD 100

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
             
                fixed3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                fixed3 normal:COLOR0; //
                fixed3 vertexWord:COLOR1; //世界空间的顶点坐标
            };

  

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = mul(v.normal, (fixed3x3)unity_WorldToObject);

                o.vertexWord = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }


            fixed4 _Diffuse;

            fixed4 _Specular;
            float _Gloss;


            fixed4 frag (v2f i) : SV_Target
            {
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 lightColor = _LightColor0.xyz;


                fixed3 normal = normalize(i.normal);
                fixed3 lightPos = _WorldSpaceLightPos0.xyz;
                fixed3 lightDir = normalize(lightPos);

                //diffuse
                fixed3 diffuse = lightColor  *  _Diffuse.xyz  * saturate(dot( lightDir , normal));


                //specular
                //view dir 减去顶点处的坐标pos 
                fixed3 viewDir = normalize (_WorldSpaceCameraPos.xyz - i.vertexWord);
                fixed3 reflectDir = reflect( -lightPos , normal );

                fixed3 specular =  lightColor * _Specular * pow( saturate(dot(viewDir, reflectDir)) , _Gloss);


                //final color
                fixed3 color = ambient + diffuse + specular ;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
