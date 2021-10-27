Shader "Unity Shader book/Chapter7/NormalMapWorldSpace"
{
    Properties
    {
        _MainTex("Main Texture",2D) = "white" {}
        _NormalMap("Normal Map",2D) = "bump" {} //unity 要勾选才可以
        _BumpScale("Bump Scale",Float) = 1.0

        _Diffuse("Diffuse",color) = (1.0,1.0,1.0,1.0)

        //specular
        _Specular("Specular",color) = (1.0 , 1.0 , 1.0 , 1.0)
        _Gloss("Gloss",Range(20,240))= 20


    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "LightMode" = "ForwardBase" }

        //把normal 由切线空间转到世界空间上去


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
                float4 texcoord0 : TEXCOORD0; //在第一个贴图上，xy 存main ,zw存normal

                float3 normal:NORMAL;   //顶点的法线信息
                float3 tanget:TANGENT;  //顶点切线属性

            };

            struct v2f
            {

                float4 uv : TEXCOORD0;

                float3 lightDir:TEXCOORD1;//lightdir
                float3 viewDir:TEXCOORD2; //


                float3 normal:TEXCOORD3; //正常的normal
                float4 tanget: COLOR0;  //用color的位置去传递

                float4 vertex : SV_POSITION;
            };

            //tangent to world  matrix : 对
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            //漫反射部分
            fixed4 _Diffuse;

            //高光部分
            fixed4 _Specular;
            float _Gloss;


            // bump 贴图
            float _BumpScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord0.xy * _MainTex_ST.xy   + _MainTex_ST.zw ;
                o.uv.zw = v.texcoord0.xy * _NormalMap_ST.xy + _NormalMap_ST.zw ;


                o.lightDir  = WorldSpaceLightDir(v.vertex);
                o.viewDir   = WorldSpaceViewDir(v.vertex);


                //法线要特殊转化不能用传统的mvp，要用一个约束矩阵才可以
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tanget = fixed4(UnityObjectToWorldDir(v.tanget.xyz) , v.tanget.w);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 abedo = tex2D( _MainTex , i.uv.xy ).xyz;

                fixed4 packNormal = tex2D( _NormalMap,i.uv.zw );
                fixed3 tanNormal = normalize( UnpackNormal(packNormal) ); //normal是tanspace下面的normal ,所以要转下世界空间


                //tan 切线空间的三个坐标轴为： tangent （x）, binormal(y) , normal(z)

                fixed3 biNormal = cross( normalize( i.normal.xyz ) ,normalize( i.tanget.xyz ) ) * i.tanget.w ;

                fixed3x3 modeltoTanMatrix = fixed3x3(i.tangent.xyz , binormal.xyz , i.normal.xyz );
                fixed3 modelNormal = mul( tanNormal , modeltoTanMatrix);

                //设置worldNormal
                fixed3 worldNormal = UnityObjectToWorldDir(modelNormal);

                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abedo ;


                //diffuse
                fixed3 lightDir =  normalize(i.lightDir);
                fixed3 lightColor = _LightColor0.xyz;

                fixed3 diffuse = lightColor.xyz * _Diffuse.xyz * abedo.xyz * max(0, dot( worldNormal , lightDir )  );


                fixed3 ViewDir = normalize(i.viewDir);
                fixed3 halfVector = normalize( lightDir + ViewDir);


                fixed3 specular = lightColor.xyz * _Specular.xyz * pow( max(0,dot( worldNormal , halfVector ) ), _Gloss )
        

                fixed3 color = ambient + diffuse + specular; //
                return fixed4( color , 1. ) ;
            }
            ENDCG
        }
    }
}
