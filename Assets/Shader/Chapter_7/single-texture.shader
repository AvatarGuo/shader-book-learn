// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shader book/Chapter7/simple texture mat"
{
    Properties{
        _MainTex("main texture",2D) = "white" {}
        _Diffuse("Diffuse",color) = (1.0,1.0,1.0,1.0)

        _Specular("Specular",color) = (1.0,1.0,1.0,1.0)
        _Gloss ("Gloss",Range(8.0,240)) = 20
    }

    SubShader {

        Tags{
                "RenderType" = "Opaque" 
                "LightMode"  = "ForwardBase"
            }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct app_data {

                fixed4 position: POSITION;
                fixed4 normal: NORMAL;

                //存疑，不太理解的地方? 模型身上的第一组贴图传过来了
                //相当于模型的第一个插槽位置，利用该插槽位置导出。
                float4 texcoord: TEXCOORD0;
            };

            struct v2f {

                fixed4 position:SV_POSITION;
                //ps中只有你传递过去的那些数据，比如贴图采样，需要uv信息从一点去做采样，（即需要去做下对应的采样）
                float2 uv:TEXCOORD0;    //还要传下语义。

                //
                fixed3 normal:TEXCOORD1;
                fixed3 worldPosition:TEXCOORD2; //blinn-phong  入射光和视口方向相加，和法线求乘积
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Diffuse;

            fixed4 _Specular;
            float _Gloss;

            v2f vert(app_data v ) {

                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                o.normal = mul(v.normal,(fixed3x3)unity_WorldToObject);

                //s
                o.worldPosition = mul( unity_ObjectToWorld , v.position);
                return o;
            };

            fixed4 frag(v2f i):SV_Target{

                //tex2Dlod 3.0设备上 可以在vs阶段采样贴图

                fixed3 abedo = tex2D(_MainTex,i.uv); //实际的采样 ,难道不需要计算a通道的值吗？
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo;

                //ambient + diffuse  + specular ，其中diffuse 也是和abedo贴图有关的
                fixed3 lightColor = _LightColor0.xyz;
                fixed3 lightDir   = normalize( _WorldSpaceLightPos0.xyz);
                fixed3 worldNormal = normalize(i.normal);

                fixed3 diffuse = abedo * lightColor * _Diffuse.xyz * max( 0,(dot( i.normal, lightDir )));

                //specular,
                fixed3 viewPos = normalize(UnityWorldSpaceViewDir(i.worldPosition));
                fixed3 halfVector = normalize(viewPos +  lightDir);

                //高光和环境的abedo贴图木有关系
                fixed3 specular = _Specular.xyz * lightColor * pow(max(0,dot(worldNormal,halfVector )) , _Gloss );

                return fixed4(ambient + diffuse  + specular , 1.);
            };


            ENDCG
        }

    }


    FallBack "Specular"

}
