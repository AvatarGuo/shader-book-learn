Shader "Unity Shader book/Chapter7/mask Texture"
{
    Properties
    {
        _MainTex ("Texture", 2D)    = "white" {}

        _BumpTex("normal map",2D)   = "bump" {}
        _BumpScale("bump scale",Float) = 1.0

        _MaskTex("mask texture",2D)  = "white" {}
        _MaskScale("mask scale",float) = 1.0

        _Diffuse("diffuse",color)   = (1.0,1.0,1.0,1.0)
        _Specular("specular",color) = (1.0,1.0,1.0,1.0)
        _Gloss("gloss",Range(20.0,240)) = 20.0
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

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;

                float4 normal:NORMAL;
                float4 tangent:TANGENT;

                float2 uv : TEXCOORD0; //xy 存储的是mainTexture,zw存储的是mask贴图的uv ，第一组纹理 

                // float2 mask:TEXCOORD1; //
            };

            struct v2f
            {
                float2 uv : TEXCOORD0; //xy 存储的是mainTexture,zw存储的是normal，
                // float2 mask_uv:TEXCOORD1; //mask 贴图采样如何计算呢？ 这里mask贴图和uv贴图一样的uv采样。
                float4 vertex : SV_POSITION;


                fixed3 tangentViewDir:TEXCOORD1;
                fixed3 tangentLightDir:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _BumpTex;
            float _BumpScale;

            sampler2D _MaskTex;
            float _MaskScale;

            float4 _Diffuse;
            float4 _Specular;
            float _Gloss;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv  = TRANSFORM_TEX(v.uv, _MainTex);

                //mask 贴图

                //切线，副切线，法线
                fixed3 normal  = v.normal.xyz;
                fixed4 tangent = v.tangent;
                fixed3 biNormal = cross( normal.xyz , tangent.xyz)*tangent.w;
                //tangent to world 和 world to tangent
                fixed3x3 modelToTangent = float3x3(tangent.xyz,biNormal.xyz,normal.xyz );

                //本身就是模型空间
                o.tangentViewDir  = mul(modelToTangent , ObjSpaceViewDir(o.vertex)).xyz ;
                o.tangentLightDir = mul(modelToTangent , ObjSpaceLightDir(o.vertex)).xyz ;

                return o;
            };

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture ,一般来说normal
                fixed4 abedo = tex2D(_MainTex, i.uv.xy);

                //
                fixed4 packedNormal = tex2D(_BumpTex,i.uv.xy);

                fixed3 tangentNoraml  = UnpackNormal(packedNormal);
                tangentNoraml.xy *= _BumpScale;
                tangentNoraml.z   = sqrt(1 - saturate( dot( tangentNoraml.xy , tangentNoraml.xy)) );

                fixed3 tangentLightDir = normalize(i.tangentLightDir);
                fixed3 tangentViewDir  = normalize(i.tangentViewDir);

                fixed3 halfVector = normalize(tangentLightDir + tangentViewDir);


                fixed3 ambient = abedo.xyz * UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = abedo.xyz * _LightColor0.xyz * _Diffuse.xyz * saturate( dot( tangentNoraml , tangentLightDir) );


                fixed4 mask  = tex2D(_MaskTex, i.uv.xy);//mask贴图也采用和mainTex一样的采样UV
                fixed3 specular = _Specular.xyz * _LightColor0.xyz * pow( saturate( dot (tangentNoraml,halfVector) )  , _Gloss) * mask.r * _MaskScale ;

                fixed3 color = ambient +  diffuse + specular;


                return fixed4( color , 1.0 );
            };
            ENDCG
        }
    }
}
