//非真实感渲染 使用一个渐变过渡贴图
Shader "Unity Shader book/Chapter7/RampTexture"
{
    Properties
    {
        _Diffuse("diffuse",color) = (1.0,1.0,1.0,1.0)

        _Specular("specular",color) = ( 1.0, 1.0, 1.0, 1.0)
        _Gloss("Gloss",Range(20.0,240)) = 20.0


        _RampTexture ("Ramp texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }


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
                float2 uv : TEXCOORD0;

                float3 normal:NORMAL;
            };

            struct v2f
            {
                // float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                fixed3 worldPos:TEXCOORD1;
                fixed3 worldNormal:TEXCOORD2;

            };

            sampler2D _RampTexture;
            float4 _RampTexture_ST; //是为了支持tilling,scale等属性，其他更复杂的需要在找下资料。

            float4 _Diffuse;
            float4 _Specular;
            float  _Gloss;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                // o.uv = TRANSFORM_TEX(v.uv, _RampTexture);

                o.worldPos = mul((fixed3x3)unity_ObjectToWorld, v.vertex.xyz);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {


                fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz ;

                fixed3 lightDir  =  normalize( UnityWorldSpaceLightDir(i.worldPos) );
                fixed3 viewDir   = normalize(UnityWorldSpaceViewDir(i.worldPos)); //都是世界坐标，两个点相减法即可
                fixed3 normalDir =  normalize(i.worldNormal);


                //dot点乘是一个数值
                fixed halfLamber =  0.5 * saturate( dot( normalDir , lightDir) ) + 0.5 ; //还是限制到0-1之间了

                fixed3 ramp     = tex2D( _RampTexture , fixed2( halfLamber , halfLamber )).xyz;

                fixed3 diffuse    =  _Diffuse.xyz * _LightColor0.xyz * ramp ;

                fixed3 halfVector   = normalize( lightDir  + viewDir  );
                fixed3 specular     = _Specular.xyz * _LightColor0.xyz * pow( max ( 0 , dot( halfVector , normalDir ) ) ,_Gloss );

                fixed3 color = ambient  +  diffuse + specular;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
