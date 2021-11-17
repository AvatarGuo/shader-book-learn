using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectsBase
{

    public Shader BrightSatConShader;
    private Material brightSatMat;

    [Range(0.0f,3.0f)]
    public float brightness;

    [Range(0.0f, 3.0f)]
    public float saturation;

    [Range(0.0f, 3.0f)]
    public float contrast;

    public Material material
    {
        get
        {
            brightSatMat = CheckShaderAndCreateMaterial(BrightSatConShader, brightSatMat);
            return brightSatMat;
        }
    }

    void OnRenderImage(RenderTexture src,RenderTexture dst)
    {
        if (material != null)
        {
            material.SetFloat("_Brightness", brightness);
            material.SetFloat("_Saturation", saturation);
            material.SetFloat("_Constrast", contrast);

            Graphics.Blit(src,dst,material);
        }
        else
        {
            Graphics.Blit(src,dst);
        }

    }

}
