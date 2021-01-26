using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class XSShaderTemplateCreator
{
    public enum BlendModes
    {
        Opaque,
        Cutout,
        Dithered,
        Transparent,
        Fade
    }

    private static string createPath = "";
    private static string templatePath = "";
    private static string lightingBRDFPath = "";
    private static string lightingFunctionsPath = "";
    private static string defines = "";
    private static string propertiesBlockPath = "";

    private static List<string> templateShaders = new List<string> { "/Fragment_Lit", "/Geometry_Lit", "/Tessellated_Lit", "/TessellatedGeometry_Lit" };
    private static List<string> newShaders = new List<string> { "/New_Fragment_Lit", "/New_Geometry_Lit", "/New_Tessellated_Lit", "/New_TessellatedGeometry_Lit" };


    private static void getPathAndCreate(int index, BlendModes blendMode)
    {
        getTemplatePath();
        if (IsAssetAFolder(Selection.activeObject))
        {
            Create(index, blendMode);
            Debug.Log("Created at " + createPath);
        }
        else
        {
            Debug.Log("Not a valid path, creating in Assets.");
            createPath = "Assets";

            Create(index, blendMode);
            Debug.Log("Created at " + createPath);
        }
    }

    //Creates file and renames the shader to the correct name
    private static void Create(int index, BlendModes blendModes)
    {
        string blendName = BlendModes.GetName(typeof(BlendModes), blendModes);
        string shaderIndex = $"{createPath}{newShaders[index]}_{blendName}";
        //Copy files to new directory
        FileUtil.CopyFileOrDirectory($"{templatePath}{templateShaders[index]}", shaderIndex);
        AssetDatabase.Refresh();

        //Derive the file name from the folder name.

        string dest = $"{shaderIndex}{templateShaders[index]}.txt";
        string final = $"{shaderIndex}{templateShaders[index]}_{blendName}.shader";
        //Path for Shared CGINC
        string finalBRDF = shaderIndex + "/LightingBRDF.cginc";
        string finalFunc = shaderIndex + "/LightingFunctions.cginc";
        string finalDefines = shaderIndex + "/Defines.cginc";

        List<string> shaderProperties = File.ReadAllLines(propertiesBlockPath).ToList();
        List<string> lines = File.ReadAllLines(dest).ToList();
        lines[0] = $"Shader \"Lit Template{templateShaders[index]}_{blendName}\"";
        for (int i = 0; i < lines.Count; i++)
        {
            if (lines[i].Contains("$PROPERTIES"))
            {
                bool hasTess = lines[i].Contains("#TESS");
                bool hasGeom = lines[i].Contains("#GEOM");

                lines.RemoveAt(i);
                for (int x = 0; x < shaderProperties.Count; x++)
                {
                    string shaderPropertiesLine = shaderProperties[x];
                    if ((shaderPropertiesLine.Contains("#TESS!") && hasTess) || (shaderPropertiesLine.Contains("#GEOM!") && hasGeom))
                        shaderPropertiesLine = shaderPropertiesLine.Substring(shaderPropertiesLine.LastIndexOf('!') + 1);

                    if (blendModes == BlendModes.Cutout && shaderPropertiesLine.Contains("#CUTOUT!"))
                        shaderPropertiesLine = shaderPropertiesLine.Substring(shaderPropertiesLine.LastIndexOf('!') + 1);

                    lines.Insert(i + x, $"        {shaderPropertiesLine}");
                }
            }

            if (lines[i].Contains("$TAGS"))
            {
                lines.RemoveAt(i);
                if (blendModes == BlendModes.Opaque)
                    lines.Insert(i, "        Tags{\"RenderType\"=\"Opaque\" \"Queue\"=\"Geometry\"}");

                if (blendModes == BlendModes.Cutout)
                    lines.Insert(i, "        Tags{\"RenderType\"=\"TransparentCutout\" \"Queue\"=\"AlphaTest\"}");

                if (blendModes == BlendModes.Dithered)
                    lines.Insert(i, "        Tags{\"RenderType\"=\"TransparentCutout\" \"Queue\"=\"AlphaTest\"}");

                if (blendModes == BlendModes.Transparent)
                    lines.Insert(i, "        Tags{\"RenderType\"=\"Transparent\" \"Queue\"=\"Transparent\"}");

                if (blendModes == BlendModes.Fade)
                    lines.Insert(i, "        Tags{\"RenderType\"=\"Transparent\" \"Queue\"=\"Transparent\"}");
            }

            if (lines[i].Contains("$BLENDMODE"))
            {
                lines.RemoveAt(i);
                if (blendModes == BlendModes.Transparent)
                    lines.Insert(i, "Blend One OneMinusSrcAlpha");

                if (blendModes == BlendModes.Fade)
                    lines.Insert(i, "Blend SrcAlpha OneMinusSrcAlpha");

            }

            if (lines[i].Contains("$BLENDDEFINE"))
            {
                lines.RemoveAt(i);
                if (blendModes == BlendModes.Cutout)
                    lines.Insert(i, "           #define ALPHATEST");

                if (blendModes == BlendModes.Dithered)
                    lines.Insert(i, "           #define DITHERED");

                if (blendModes == BlendModes.Transparent)
                    lines.Insert(i, "           #define TRANSPARENT");

                if (blendModes == BlendModes.Fade)
                    lines.Insert(i, "           #define TRANSPARENT");
            }
        }
        File.WriteAllLines(dest, lines);

        //Move main Files
        FileUtil.MoveFileOrDirectory(dest, final);
        //Move Shared CGINCs
        FileUtil.CopyFileOrDirectory(lightingBRDFPath, finalBRDF);
        FileUtil.CopyFileOrDirectory(lightingFunctionsPath, finalFunc);
        FileUtil.CopyFileOrDirectory(defines, finalDefines);

        AssetDatabase.Refresh();
    }

    private static void getTemplatePath()
    {
        string[] guids1 = AssetDatabase.FindAssets("XSShaderTemplateCreator", null);
        string untouchedString = AssetDatabase.GUIDToAssetPath(guids1[0]);
        string[] splitString = untouchedString.Split('/');

        ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
        ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);

        templatePath = string.Join("/", splitString);
        templatePath += "/Templates";
        lightingBRDFPath = templatePath + "/Shared/LightingBRDF.cginc";
        lightingFunctionsPath = templatePath + "/Shared/LightingFunctions.cginc";
        propertiesBlockPath = templatePath + "/Shared/Properties.txt";
        defines = templatePath + "/Shared/Defines.cginc";
    }

    private static bool IsAssetAFolder(Object obj)
    {
        if (obj == null)
            return false;

        createPath = AssetDatabase.GetAssetPath(obj.GetInstanceID());

        if (createPath.Length > 0)
        {
            if (Directory.Exists(createPath))
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        return false;
    }

    //Opaque
    [MenuItem("Assets/Create/Shader/Lit/Opaque/Fragment")]
    private static void CreateShaderFragLit()
    {
        getPathAndCreate(0, BlendModes.Opaque);
    }

    [MenuItem("Assets/Create/Shader/Lit/Opaque/Geometry")]
    private static void CreateShaderGeoLit()
    {
        getPathAndCreate(1, BlendModes.Opaque);
    }

    [MenuItem("Assets/Create/Shader/Lit/Opaque/Tessellated")]
    private static void CreateShaderTessLit()
    {
        getPathAndCreate(2, BlendModes.Opaque);
    }

    [MenuItem("Assets/Create/Shader/Lit/Opaque/TessellatedGeometry")]
    private static void CreateShaderTessGeoLit()
    {
        getPathAndCreate(3, BlendModes.Opaque);
    }

    //Cutout
    [MenuItem("Assets/Create/Shader/Lit/Cutout/Fragment")]
    private static void CreateShaderFragLitCutout()
    {
        getPathAndCreate(0, BlendModes.Cutout);
    }

    [MenuItem("Assets/Create/Shader/Lit/Cutout/Geometry")]
    private static void CreateShaderGeoLitCutout()
    {
        getPathAndCreate(1, BlendModes.Cutout);
    }

    [MenuItem("Assets/Create/Shader/Lit/Cutout/Tessellated")]
    private static void CreateShaderTessLitCutout()
    {
        getPathAndCreate(2, BlendModes.Cutout);
    }

    [MenuItem("Assets/Create/Shader/Lit/Cutout/TessellatedGeometry")]
    private static void CreateShaderTessGeoLitCutout()
    {
        getPathAndCreate(3, BlendModes.Cutout);
    }

    //Dithered
    [MenuItem("Assets/Create/Shader/Lit/Dithered/Fragment")]
    private static void CreateShaderFragLitDithered()
    {
        getPathAndCreate(0, BlendModes.Dithered);
    }

    [MenuItem("Assets/Create/Shader/Lit/Dithered/Geometry")]
    private static void CreateShaderGeoLitDithered()
    {
        getPathAndCreate(1, BlendModes.Dithered);
    }

    [MenuItem("Assets/Create/Shader/Lit/Dithered/Tessellated")]
    private static void CreateShaderTessLitDithered()
    {
        getPathAndCreate(2, BlendModes.Dithered);
    }

    [MenuItem("Assets/Create/Shader/Lit/Dithered/TessellatedGeometry")]
    private static void CreateShaderTessGeoLitDithered()
    {
        getPathAndCreate(3, BlendModes.Dithered);
    }

    //Transparent
    [MenuItem("Assets/Create/Shader/Lit/Transparent/Fragment")]
    private static void CreateShaderFragLitTransparent()
    {
        getPathAndCreate(0, BlendModes.Transparent);
    }

    [MenuItem("Assets/Create/Shader/Lit/Transparent/Geometry")]
    private static void CreateShaderGeoLitTransparent()
    {
        getPathAndCreate(1, BlendModes.Transparent);
    }

    [MenuItem("Assets/Create/Shader/Lit/Transparent/Tessellated")]
    private static void CreateShaderTessLitTransparent()
    {
        getPathAndCreate(2, BlendModes.Transparent);
    }

    [MenuItem("Assets/Create/Shader/Lit/Transparent/TessellatedGeometry")]
    private static void CreateShaderTessGeoLitTransparent()
    {
        getPathAndCreate(3, BlendModes.Transparent);
    }

    //Fade
    [MenuItem("Assets/Create/Shader/Lit/Fade/Fragment")]
    private static void CreateShaderFragLitFade()
    {
        getPathAndCreate(0, BlendModes.Fade);
    }

    [MenuItem("Assets/Create/Shader/Lit/Fade/Geometry")]
    private static void CreateShaderGeoLitFade()
    {
        getPathAndCreate(1, BlendModes.Fade);
    }

    [MenuItem("Assets/Create/Shader/Lit/Fade/Tessellated")]
    private static void CreateShaderTessLitFade()
    {
        getPathAndCreate(2, BlendModes.Fade);
    }

    [MenuItem("Assets/Create/Shader/Lit/Fade/TessellatedGeometry")]
    private static void CreateShaderTessGeoLitFade()
    {
        getPathAndCreate(3, BlendModes.Fade);
    }
}