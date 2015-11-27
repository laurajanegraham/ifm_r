# ---------------------------------------------------------------------------
# create_scenario_shapes.py
# Created on: 2014-04-25
# Usage: process the scenario shape files for each species
# Description: creates files of the suitable habitat for each species and merges
#              so that each patch is realistic rather than being demarcated by
#              artificial boundaries or boundaries between different habitats.
#              These are based on the projected scenarios.
# ---------------------------------------------------------------------------

# Import arcpy module
import arcpy
import os
import datetime
import sys
from arcpy import env
from sys import argv


specieslist = ["marsh.tit"]
scenarios = ["s1_60_perc", "s3_60_perc"]

for species in specieslist:
    for scenario in scenarios:
        lcm = ("C:\\ArcMapWorkingFolder\\model_input\\" + scenario + ".shp")
        freshwater = ("C:\\ArcMapWorkingFolder\\model_input\\freshwater.shp")
        if arcpy.Exists("lcmlyr"):
            arcpy.Delete_management("lcmlyr")
        arcpy.MakeFeatureLayer_management (lcm, "lcmlyr")

        freshwater_buffer = "C:\\ArcMapWorkingFolder\\working\\freshwater_buffer.shp"
        dissolve_shp = "C:\\ArcMapWorkingFolder\\working\\dissolve.shp"
        buffer_shp = "C:\\ArcMapWorkingFolder\\working\\buffer.shp"
        m_to_s = "C:\\ArcMapWorkingFolder\\working\\m_to_s.shp"
        add_buffer_id = "C:\\ArcMapWorkingFolder\\working\\add_buffer_id.shp"
        output_file = "C:\\ArcMapWorkingFolder\\model_output\\" + species + "\\" + scenario + ".shp"

        # this section deletes all the files in the working folder
        dirPath = "C:\\ArcMapWorkingFolder\\working"
        fileList = os.listdir(dirPath)
        for fileName in fileList:
         os.remove(dirPath+"/"+fileName)
        # end of file deleting section

        # SECTION FOR COMMON TOAD - ONLY SELECTS HABITAT WHICH IS WITHIN DISPERSAL DISTANCE OF FRESHWATER.
        if species == "common.toad":
            arcpy.Buffer_analysis(freshwater, freshwater_buffer, "700 Meters", "FULL", "ROUND", "ALL", "") # B. Bufo
            arcpy.SelectLayerByLocation_management("lcmlyr", "intersect", freshwater_buffer)

        # get rid of artificial boundaries and divisions 
        # update this section with species habitat preferences if new species are added.    
        if species in ("blackbird", "dunnock"):
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (1,2,3,4,5,6,7,8)') # BLACKBIRD & DUNNOCK
        elif species == "corn.bunting":
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (3,4,5,6,8)') # CORN BUNTING
        elif species in ("greenfinch", "tree.sparrow"):
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (1,2,3)') # GREENFINCH & TREE SPARROW
        elif species in ("jay", "great.spotted.woodpecker", "spotted.flycatcher"):
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (1,2)') # JAY & GREAT SPOTTED WOODPECKER & SPOTTED FLYCATCHER
        elif species == "european.nightjar":
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (1,2,10,11)') # EUROPEAN NIGHTJAR
        elif species == "goldfinch":
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (3,5)') # GOLDFINCH
        elif species in ("marsh.tit", "blackcap"):
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (1)') # MARSH TIT & BLACKCAP
        elif species == "yellowhammer":
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (3,5,10,11)') # YELLOWHAMMER
        elif species in ("common.frog"):
            arcpy.SelectLayerByAttribute_management("lcmlyr","NEW_SELECTION", ' "lcm_class" in (1, 2, 3, 4, 5, 6, 8, 9)') # COMMON FROG
            arcpy.Append_management(freshwater, "lcmlyr", "NO_TEST")
        elif species in ("common.toad"):
            arcpy.SelectLayerByAttribute_management("lcmlyr","SUBSET_SELECTION", ' "lcm_class" in (1, 2, 5, 6, 8, 9)') # COMMON TOAD
            arcpy.Append_management(freshwater, "lcmlyr", "NO_TEST")



        arcpy.Dissolve_management("lcmlyr", dissolve_shp, "", "", "SINGLE_PART", "DISSOLVE_LINES") # remove artificial boundaries (and groupings) caused by ownership/diff habitat types
        arcpy.Buffer_analysis(dissolve_shp, buffer_shp, "1.5 Meters", "FULL", "ROUND", "ALL", "") # remove artificial boundaries caused by small paths and roads (total 3m means paths and small roads are accounted for but large roads are not - should be realistic?)
        print "Buffer analysis done: " + str(datetime.datetime.now())
        arcpy.MultipartToSinglepart_management(buffer_shp, m_to_s)
        arcpy.AddField_management(m_to_s, "buffer_ID", "LONG", "", "", "", "", "NON_NULLABLE", "NON_REQUIRED", "")
        arcpy.CalculateField_management(m_to_s, "Buffer_ID", "[FID]", "VB", "")
        arcpy.SpatialJoin_analysis(dissolve_shp, m_to_s, add_buffer_id, "JOIN_ONE_TO_ONE", "KEEP_ALL")
        arcpy.Dissolve_management(add_buffer_id, output_file, "Buffer_ID", "", "MULTI_PART", "DISSOLVE_LINES")

        # add necessary fields
        arcpy.AddField_management(output_file, "area_ha", "DOUBLE", 12, 4)
        arcpy.AddField_management(output_file, "X", "DOUBLE", 18, 11)
        arcpy.AddField_management(output_file, "Y", "DOUBLE", 18, 11)
        expressionx = "float(!SHAPE.CENTROID!.split()[0])"
        expressiony = "float(!SHAPE.CENTROID!.split()[1])"
        expressionarea = "float(!SHAPE.AREA@HECTARES!)"


        arcpy.CalculateField_management(output_file, "X", expressionx,
                                        "PYTHON")
        arcpy.CalculateField_management(output_file, "Y", expressiony,
                                        "PYTHON")
        arcpy.CalculateField_management(output_file, "area_ha", expressionarea,
                                        "PYTHON")
