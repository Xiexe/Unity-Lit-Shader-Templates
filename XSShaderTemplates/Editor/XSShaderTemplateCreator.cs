using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class XSShaderTemplateCreator 
{
    private static string createPath = "";
    private static string templatePath = "";

    private static List<string> templateShaders = new List<string>{ "/Fragment_Lit", "/Geometry_Lit", "/Tessellated_Lit", "/TesellatedGeometry_Lit" };
    private static List<string> newShaders = new List<string>{ "/New_Fragment_Lit", "/New_Geometry_Lit", "/New_Tessellated_Lit", "/New_TesellatedGeometry_Lit" };

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

        if(IsAssetAFolder(Selection.activeObject))
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
        //Copy files to new directory
        FileUtil.CopyFileOrDirectory(templatePath + templateShaders[index], createPath + newShaders[index]);
        AssetDatabase.Refresh();

        //Derive the file name from the folder name.
        string dest = createPath + newShaders[index] + templateShaders[index] + ".txt";
        string final = createPath + newShaders[index] + templateShaders[index] + ".shader";

        string[] lines = File.ReadAllLines(dest);
        lines[0] = "Shader " + "\"Custom" + templateShaders[index] + "\"";
        File.WriteAllLines(dest, lines);

        FileUtil.MoveFileOrDirectory(dest, final);
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
