using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Bloom : PostEffectsBase
{
    public Shader bloomShader;

    [Range(0, 4)]
    public int iterations = 3;
    [Range(0.2f, 3.0f)]
    public float blurSpeed = 0.5f;

    [Range(1, 8)]
    public int downSample = 1;


    //亮度
    [Range(0, 4.0f)]
    public float luminanceThreshold;


    private Material _material;

    public Material material
    {
        get
        {
            if (_material == null)
            {
                _material = CheckShaderAndCreateMaterial(bloomShader,_material);
            }

            return _material;
        }

    }

    void OnRenderImage(RenderTexture src,RenderTexture dst)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            int rtW = src.width  / downSample;
            int rtH = src.height / downSample;

            
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW,rtH,0);
            Graphics.Blit(src , buffer0 ,material ,0);

            //
            for (int i = 0; i < iterations; i++)
            {
                //设置模糊级别
                material.SetFloat("_BlurSize", 1.0f + i * blurSpeed);

                
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                //render pass1
                Graphics.Blit(buffer0, buffer1, material, 1);
                RenderTexture.ReleaseTemporary(buffer0);


                
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW , rtH , 0);
                //render pass 2
                Graphics.Blit(buffer0, buffer1, material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;

            }
            
            //pass 3 混合bloom参数
            material.SetTexture("_Bloom",buffer0);
            Graphics.Blit(src,dst,material,3);

            RenderTexture.ReleaseTemporary(buffer0);


        }
        else
        {
            Graphics.Blit(src,dst);
        }


    }


}
