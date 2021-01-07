﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class XSShaderTemplateCreator
{
    private static string createPath = "";
    private static string templatePath = "";
    private static string lightingBRDFPath = "";
    private static string lightingFunctionsPath = "";
    private static string defines = "";
    private static string propertiesBlockPath = "";

    private static List<string> templateShaders = new List<string> { "/Fragment_Lit", "/Geometry_Lit", "/Tessellated_Lit", "/TessellatedGeometry_Lit" };
    private static List<string> newShaders = new List<string> { "/New_Fragment_Lit", "/New_Geometry_Lit", "/New_Tessellated_Lit", "/New_TessellatedGeometry_Lit" };

    [MenuItem("Assets/Create/Shader/Custom/Fragment_Lit")]
    private static void CreateShaderFragLit()
    {
        getPathAndCreate(0);
    }

    [MenuItem("Assets/Create/Shader/Custom/Geometry_Lit")]
    private static void CreateShaderGeoLit()
    {
        getPathAndCreate(1);
    }

    [MenuItem("Assets/Create/Shader/Custom/Tessellated_Lit")]
    private static void CreateShaderTessLit()
    {
        getPathAndCreate(2);
    }

    [MenuItem("Assets/Create/Shader/Custom/TessellatedGeometry_Lit")]
    private static void CreateShaderTessGeoLit()
    {
        getPathAndCreate(3);
    }

    private static void getPathAndCreate(int index)
    {
        getTemplatePath();

        if (IsAssetAFolder(Selection.activeObject))
        {
            Create(index);
            Debug.Log("Created at " + createPath);
        }
        else
        {
            Debug.Log("Not a valid path, creating at parent folder.");
            createPath = createPath.Substring(0, createPath.LastIndexOf("/") + 1);

            Create(index);
            Debug.Log("Created at " + createPath);
        }
    }

    //Creates file and renames the shader to the correct name
    private static void Create(int index)
    {
        string shaderIndex = createPath + newShaders[index];
        //Copy files to new directory
        FileUtil.CopyFileOrDirectory(templatePath + templateShaders[index], shaderIndex);
        AssetDatabase.Refresh();

        //Derive the file name from the folder name.
        string dest = shaderIndex + templateShaders[index] + ".txt";
        string final = shaderIndex + templateShaders[index] + ".shader";
        //Path for Shared CGINC
        string finalBRDF = shaderIndex + "/LightingBRDF.cginc";
        string finalFunc = shaderIndex + "/LightingFunctions.cginc";
        string finalDefines = shaderIndex + "/Defines.cginc";

        List<string> shaderProperties = File.ReadAllLines(propertiesBlockPath).ToList();
        List<string> lines = File.ReadAllLines(dest).ToList();
        lines[0] = "Shader " + "\"Custom" + templateShaders[index] + "\"";
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

                    lines.Insert(i + x, $"        {shaderPropertiesLine}");
                }
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
}
