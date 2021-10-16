Shader "Unity Shader book/Chapter6/Specular vertex Shader"
{
   Properties{
        _Diffuse("diffuse",color) = ( 1.0 , 1.0 , 1.0 , 1.0 )

        // 高光项 相关
        _SPECULAR("Specular",color) = ( 1.0 , 1.0 , 1.0 , 1.0 )
        _GLOSS("gloss", Range(8.0, 255)) = 20
   }

    SubShader{
        

        Tags{
                "RenderType"="Opaque" 
                "LightMode"="ForwardBase"
            }


        Pass {


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"


            struct appdata{

                float4 position:POSITION;
                fixed3 normal:NORMAL;
            };

            struct v2f {
                //system
                fixed4 position:SV_POSITION;

                fixed3 color:COLOR;
            };

            fixed4 _Diffuse;
            //
            fixed4 _SPECULAR;
            float  _GLOSS;
            

            v2f vert(appdata v){
                v2f o;
                o.position = UnityObjectToClipPos(v.position);

                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //
                fixed3 lightColor   = _LightColor0.xyz;
                fixed3 lightPos     = _WorldSpaceLightPos0.xyz;

                //normal变换
                fixed3 normal = normalize(mul( v.normal ,  (fixed3x3)unity_WorldToObject)); //逆转置矩阵
                fixed3 lightDir = normalize(lightPos);

                //计算下diffuse光照(漫反射)
                fixed3 diffuse = lightColor * _Diffuse.xyz * saturate(dot( normal, lightDir ));

                //计算下高光 specular 的部分
          
                //注意这个reflect 函数的lightDir 方向为 负值（以light方向为起点看过去） 
                //这里需要画个图表示下方向。
                fixed3 reflectDir =  normalize ( reflect ( -lightDir , normal) );

                //这里需要记录一下，视角方向是从该顶点看过去的方向，而不是直接拿 _WorldSpaceCameraPos 来算
                //因为各个顶点看过去方向是不同的
                // fixed3 viewDir = normalize( _WorldSpaceCameraPos.xyz );
                fixed3 viewDir = normalize (_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld , v.position));

                //
                fixed3 gloss = pow(saturate( dot ( reflectDir , viewDir ) ) , _GLOSS);
                fixed3 specular = lightColor * _SPECULAR.xyz * gloss;

                o.color = ambient + diffuse + specular;

                return o;
            };

            fixed4 frag(v2f i ):SV_Target
            {
                return fixed4(i.color,1);
            };

            ENDCG

        }


    }


    FallBack "Specular"


}
