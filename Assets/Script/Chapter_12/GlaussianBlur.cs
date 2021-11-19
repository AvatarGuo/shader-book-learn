using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlaussianBlur : PostEffectsBase
{

    public Shader GaussusianShader;

    private Material _material;

    [Range(0,4)]
    public float iterations = 3f;
    [Range(0.2f,3.0f)]
    public float blurSpeed = 0.5f;

    [Range(1,8)]
    public int downSample = 1;

    public Material material
    {
        get
        {
            if (_material == null)
            {
                _material = CheckShaderAndCreateMaterial(GaussusianShader, _material);
            }

            return _material;
        }

    }

    void OnRenderImage(RenderTexture src,RenderTexture dst)
    {
        //rt buffer 和 采样cache

        //核心，先横着做一遍高斯，存储起来， 在竖直做一遍高斯，两个叠加起来


        //正常的采样
        //这边定义一个pass，然后shader里面计算该pass
        // var mat = material;
        // if (mat)
        // {
        //     int rtW = src.width;
        //     int rtH = src.height;
        //     RenderTexture buffer = RenderTexture.GetTemporary(rtW,rtH,0);
        //
        //     //render horizontal pass
        //     Graphics.Blit(src,buffer,mat,0);
        //
        //     //
        //     Graphics.Blit(buffer,dst,mat,1);
        //
        //     Graphics.Blit(src,dst,mat);
        //
        //     RenderTexture.ReleaseTemporary(buffer);
        //
        // }
        // else
        // {
        //     Graphics.Blit(src, dst);
        // }

        //downSamle 
        // var mat = material;
        // if (mat)
        // {
        //     int rtW = src.width;
        //     int rtH = src.height;
        //
        //     RenderTexture buffer = RenderTexture.GetTemporary(rtW / downSample,rtH / downSample ,0);
        //     buffer.filterMode = FilterMode.Bilinear;
        //
        //     Graphics.Blit(src, buffer,mat, 0);
        //
        //     //已经down samle 之后的图片了
        //     Graphics.Blit(buffer,dst,mat,1);
        //
        //
        //     RenderTexture.ReleaseTemporary(buffer);
        //
        // }
        // else
        // {
        //     Graphics.Blit(src,dst);
        // }



        //Gassusion multi sampler

        var mat = material;
        if (mat)
        {

            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            // int rtW = src.width;
            // int rtH = src.height;

            
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW,rtH,0);
            Graphics.Blit(src,buffer0,mat,0);

            //多次叠加，一个buffer 横竖两次设置
            for (int i = 0; i < iterations; i++)
            {
                //设置模糊级别
                mat.SetFloat("_BlurSize",1.0f + i * blurSpeed );


                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW,rtH,0);
                
                Graphics.Blit(buffer0, buffer1 , mat,0);

                RenderTexture.ReleaseTemporary(buffer0);

                buffer0 = buffer1;
                buffer1 =  RenderTexture.GetTemporary(rtW,rtH , 0);
                
                Graphics.Blit(buffer0,buffer1,mat ,1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;

            }

            Graphics.Blit(buffer0 , dst);
            RenderTexture.ReleaseTemporary(buffer0);


        }
        else
        {
            Graphics.Blit(src,dst);
        }

    }

}
