Shader "Unity Shader book/Chapter10/ReflectionShader"
{
    Properties
    {

        _Color("color tint",color) = ( 1.0, 1.0, 1.0, 1.0)

        _Specular("specular",color) = (1.0 ,1.0, 1.0 ,1.0)
        _Gloss("gloss",range(20.0,240)) = 20


        _ReflectColor("reflect color",color) = (1.0,1.0,1.0,1.0)

        //和diffuse做线性lerp
        _ReflectAmont("reflect amont",range(0,1)) = 1

        //可以通过cpu 传参数传过来
        _CubeMap("Reflection CubeMap",Cube) = "_Skybox" {}
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

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                float3 worldNormal:TEXCOORD1;

                float3 worldLightDir:TEXCOORD2;
                float3 worldViewDir:TEXCOORD3;

                //反射方向 即观察方向的反射方向
                float3 worldRef1: TEXCOORD4;
            };

            fixed4 _Color;
            fixed4 _Specular;
            fixed _Gloss;

            //https://docs.unity3d.com/560/Documentation/Manual/SL-PropertiesInPrograms.html
            samplerCUBE _CubeMap; 
            fixed _ReflectAmont;
            fixed4 _ReflectColor;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                //正常变换矩阵的逆转矩阵
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                fixed3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                o.worldLightDir = UnityWorldSpaceLightDir(worldPos);
                o.worldViewDir  = UnityWorldSpaceViewDir(worldPos);

                //世界空间的反射方向
                o.worldRef1 = reflect( -o.worldViewDir , o.worldNormal );

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize( i.worldNormal );

                fixed3 lightDir = normalize( i.worldLightDir );
                fixed3 viewDir = normalize( i.worldViewDir );

                fixed3 halfVector = normalize(lightDir + viewDir);



                fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse  = _LightColor0.xyz * _Color.xyz * saturate(dot(worldNormal,lightDir));
                fixed3 specular = _LightColor0.xyz * _Specular.xyz * pow(max(0,dot(worldNormal,halfVector)) , _Gloss);

                fixed3 worldRef1 =  i.worldRef1;//texCUBE函数不一定需要归一化
                
                fixed3 reflection = texCUBE( _CubeMap ,worldRef1  ).rgb * _ReflectColor.xyz ;


                fixed3 color = ambient + lerp(diffuse, reflection , _ReflectAmont) + specular;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
