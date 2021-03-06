# lumpR/reservoir_lumped.R
# Copyright (C) 2016-2018 Tobias Pilz, Till Francke
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#' Generation of WASA parameter files for simulation of lumped reservoirs ("small reservoirs")
#' 
#' Function generates the WASA parameter files lake.dat and lake_number.dat from
#' a pre-processed reservoir vector and a subbasin raster file stored in a GRASS
#' location.
#' 
#' @param res_vect Name of reservoir vector map in GRASS location. Can be point
#'      or polygon feature (e.g. reservoir centroids).
#'      If it has the columns 'volume' with information on volume in [m^3] or column 'area'
#'      with information on lake area in [m^2], these will be used for computation. 
#'      If none is encountered, 'area' can be generated from the area of the polygons, if present.
#' @param subbas Name of subbasin raster map in GRASS location. Can be created with
#'      \code{\link[lumpR]{calc_subbas}}.
#' @param res_vect_classified Output: Name for the vector reservoir map to be created in GRASS
#'      location. This is a point map based on \code{res_vect} with information of area or volume (whichever is missing),
#'      ID of the subbasin in which the reservoir is located, and the classified size class
#'      appended to the attribute table. If \code{NULL} (default) it will not be created.
#' @param dir_out Character string specifying output directory (will be created if
#'      not available and files will be overwritten if \code{overwrite = TRUE}.
#' @param reservoirs_small_classes_file Parameters for the reservoir size classes.
#'      See \code{\link{db_fill}}.
#' @param r_subbas_contains_reservoirs_small_file Distribution of small reservoirs in subbasins.
#'      See \code{\link{db_fill}}.
#' @param res_param A \code{data.frame} object containing parameters for the reservoir
#'      size classes. The default parameter set is adjusted to semi-arid Brazil.
#'      See \code{Details}.
#' @param keep_temp \code{logical}. Set to \code{TRUE} if temporary files shall be kept
#'      in the GRASS location, e.g. for debugging or further analyses. Default: \code{FALSE}.
#' @param overwrite \code{logical}. Shall output of previous calls of this function be
#'      deleted? If \code{FALSE} the function returns an error if output already exists.
#'      Default: \code{FALSE}.
#' @param silent \code{logical}. Shall the function be silent (also suppressing warnings
#'      of internally used GRASS functions)? Default: \code{FALSE}.
#' @return The two output files specified in \code{reservoirs_small_classes_file} and \code{r_subbas_contains_reservoirs_small_file}; and
#'      the vector map \code{res_vect_class} in GRASS
#'      
#' @note Prepare GRASS location and necessary spatial objects in advance and start
#'      GRASS session in R using \code{\link[rgrass7]{initGRASS}}.
#'      
#'      Use \code{\link{reservoir_strategic}} to prepare the input for large / strategic reservoirs. 
#'      
#'      Points in \code{res_vect} not overlapping with any \code{subbas} will be
#'      silently removed during processing!
#'      
#'      Polygons overlapping over various subbasins will be classified to the subbasin
#'      containing the polygon's centroid. If that occurs frequently, you should
#'      consider running \code{\link[lumpR]{reservoir_outlet}} in advance where
#'      reservoir outlet locations are estimated instead of using the centroid.
#'      
#' @details This function creates WASA input files which are needed to run the model
#'      with option \code{doacudes=.T.} (simulate small unlocated reservoirs).
#'      
#'      The default values for \code{res_param} set were estimated by Molle (1989) for the 
#'      \bold{semi-arid NE of Brazil} and need to be adjusted if applied to some other region!
#'      
#'      \bold{lake_file} / \bold{res_param}\cr
#'      Specification of parameters for the reservoir size classes. Note that \code{lake_file} and \code{res_param} have the same order, but different header names! If information
#'      on 'maxlake0' / 'vol_max' is not available, you can specify 'area_max' in \code{res_param},
#'      i.e. the maximum area of reservoir size classes in \emph{m^2}. This is internally converted to volume
#'      by relationship of Molle (1989) using parameters 'alpha_Molle' and 'damk_Molle'.
#'      If neither is given (default), the values will be estimated from the 20 % and 100 %
#'      percentiles of the value distribution of area or volume in \code{res_vect} by interpolation
#'      between both values using a logarithmic relationship.
#'      
#'      \emph{Reservoir_class-ID / class}\cr
#'      ID of reservoir size class.
#'      
#'      \emph{maxlake0 / vol_max}\cr
#'      Upper limit of reservoir size class in terms of volume in \emph{m^3}.
#'      
#'      \emph{lake_vol0_factor / f_vol_init}\cr
#'      Fraction of storage capacity that indicates the initial water volume in the
#'      reservoir size classes (\emph{dimensionless}).
#'      
#'      \emph{lake_change / class_change}\cr
#'      Factor that indicates yearly variation in the number of reservoirs of the size
#'      classes (\emph{dimensionless}).
#'      
#'      \emph{alpha_Molle, damk_Molle}\cr
#'      Parameters of the area-volume relationship in the reservoir size classes:
#'      Area = alpha_Molle * damk_Molle * (Volume / damk_Molle)^( (alpha_Molle - 1) / alpha_Molle).
#'      Unit of Area: \emph{m^2}, unit of Volume: \emph{m^3}.
#'      
#'      \emph{damc_hrr, damd_hrr}\cr
#'      Parameters of the spillway rating curve in the reservoir size classes:
#'      Overflow = damc_hrr * Height^(damd_hrr). 
#'      Unit of Overflow: \emph{m^3/s}, unit of Height (over spillway): \emph{m}. 
#'      
#'      
#'      
#' @references 
#' 
#'      lumpR package introduction with literature study and sensitivity analysis:\cr
#'      Pilz, T.; Francke, T.; Bronstert, A. (2017): lumpR 2.0.0: an R package facilitating
#'      landscape discretisation for hillslope-based hydrological models.
#'      \emph{Geosci. Model Dev.}, 10, 3001-3023, doi: 10.5194/gmd-10-3001-2017
#'      
#'      WASA model in general:\cr
#'      Guentner, A. (2002): Large-scale hydrological modelling in the semi-arid 
#'      North-East of Brazil. \emph{PIK Report 77}, Potsdam Institute for Climate
#'      Impact Research, Potsdam, Germany.
#'      
#'      Reservoir module of the WASA model:\cr
#'      Mamede, G. L. (2008):  Reservoir sedimentation in dryland catchments: Modeling
#'      and management. PhD Thesis, University of Potsdam, Germany.
#'      
#'      Reservoir parameter set herein given as standard values:\cr
#'      Molle, F. (1989): Evaporation and infiltration losses in small reservoirs.
#'      \emph{Serie Hydrologia}, 25, SUDENE / ORSTOM, Recife, Brazil, in Portuguese.
#'      
#' 
#' @author Tobias Pilz \email{tpilz@@uni-potsdam.de}, Till Francke \email{francke@@uni-potsdam.de}

reservoir_lumped <- function(
  # INPUT #
  res_vect=NULL,
  subbas=NULL,
  # OUTPUT #
  res_vect_classified=NULL,
  dir_out="./",
  reservoirs_small_classes_file="reservoirs_small_classes.dat",
  r_subbas_contains_reservoirs_small_file="r_subbas_contains_reservoirs_small.dat",

  # PARAMETERS #
  res_param=data.frame(class=1:5,
                       f_vol_init=0.2,
                       class_change=0,
                       alpha_Molle=2.7,
                       damk_Molle=1500,
                       damc_hrr=c(7,14,21,28,35),
                       damd_hrr=1.5),
  keep_temp=F,
  overwrite=F,
  silent=F
) {
  
### PREPROCESSING ###----------------------------------------------------------
  
  check_raster(subbas,"subbas")
  check_vector(res_vect,"res_vect")
  if(!silent) message("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
  if(!silent) message("% START reservoir_lumped()")
  if(!silent) message("%")
  if(!silent) message("% Initialise function...")
  
  # CHECKS #
  
  tryCatch(gmeta(), error = function(e) stop("Cannot execute GRASS commands. Maybe you forgot to run initGRASS()?"))
  
  # spatial input from GRASS location
  if(is.null(res_vect))
    stop("The name of a reservoir vector file 'res_vect' within the mapset of your initialised GRASS session has to be given!")
  if(is.null(subbas))
    stop("The name of a subbasin raster file 'subbas' within the mapset of your initialised GRASS session has to be given!")
  if(is.null(res_vect_classified))
  {
    warning("Classified reservoir point vector file 'res_vect_classified' will NOT be created!")
    res_vect_classified = paste0(res_vect,"_t")
  }
  # check 'res_param'
  if(!is.data.frame(res_param))
    stop("'res_param' has to be a data.frame!")
  if(is.null(res_param$class))
    stop("'res_param' needs column 'class' to be given!")
  if(is.null(res_param$f_vol_init))
    stop("'res_param' needs column 'f_vol_init' to be given!")
  if(is.null(res_param$class_change))
    stop("'res_param' needs column 'class_change' to be given!")
  if(is.null(res_param$alpha_Molle))
    stop("'res_param' needs column 'alpha_Molle' to be given!")
  if(is.null(res_param$damk_Molle))
    stop("'res_param' needs column 'damk_Molle' to be given!")
  if(is.null(res_param$damc_hrr))
    stop("'res_param' needs column 'damc_hrr' to be given!")
  if(is.null(res_param$damd_hrr))
    stop("'res_param' needs column 'damd_hrr' to be given!")
  
  #check type of input vector
  cmd_out <- execGRASS("v.info", map=res_vect, flags="t", intern=TRUE) 
  is_point_map = !any(cmd_out == "points=0") #is this is a point vector (instead of polygons)?
  # check that reservoir vector file has column 'volume' or 'area'
  cmd_out <- execGRASS("v.info", map=res_vect, flags=c("c"), intern=T, ignore.stderr = T)
  cmd_out <- unlist(strsplit(cmd_out, "|", fixed=T))
  ncols <- grep("area|volume", cmd_out, value = T)
  
  if (!"area" %in% ncols) #no area column found
  {  
    if(is_point_map)
    {  
      if (!"volume" %in% ncols) #no area column found
        stop("Attribute table of input vector 'res_vect' needs column 'area' (in m^2) OR (preferrably) 'volume' (in m^3)!") 
    } else  {  #this is a vector map
        if(!silent) message("% No area information found in attribute table, using area of polygons instead...")
    }  
  }
  # if(length(ncols) == 2)
  #   cols <- "volume"
  # else
  #   cols <- ncols
  
  
  # CLEAN UP AND RUNTIME OPTIONS # 
  # suppress annoying GRASS outputs
  tmp_file <- file(tempfile(), open="wt")
  sink(tmp_file, type="output")
  
  # also supress warnings in silent mode
  if(silent){
    tmp_file2 <- file(tempfile(), open="wt")
    sink(tmp_file2, type="message")
    oldw <- getOption("warn")
    options(warn = -1)
  }
  

### CALCULATIONS ###-----------------------------------------------------------
  tryCatch({
    
    # remove mask if there is any (and ignore error in case there is no mask)
    tryCatch(suppressWarnings(execGRASS("r.mask", flags=c("r"))), error=function(e){})
    
    # create output dir
    dir.create(dir_out, recursive=T, showWarnings=F)
    
    # check output directory
    if (!overwrite & (file.exists(paste(dir_out,reservoirs_small_classes_file,sep="/")) |
                      file.exists(paste(dir_out,r_subbas_contains_reservoirs_small_file,sep="/"))) )
      stop(paste0("Output file(s) ", reservoirs_small_classes_file, " and/or ",r_subbas_contains_reservoirs_small_file, " already exist(s) in ", dir_out, "!"))
    
    # remove output of previous function calls if overwrite=T
    if (overwrite) {
      cmd_out <- execGRASS("g.remove", type="raster,vector", pattern=paste0("*_t,", res_vect_classified), flags=c("f", "b"), intern=T)
    } else {
      # remove temporary maps in any case
      cmd_out <- execGRASS("g.remove", type="raster,vector", pattern="*_t", flags=c("f", "b"), intern=T)
    }
    
    if(!silent) message("% OK")
    
          
    if (!is_point_map) #is this a point-vector file? If not, convert to points
    {
      if(!silent) message("%")
      if(!silent) message("% Argument 'res_vect' detected as polygon map. Derive centroids as points...")
      #check for 'area field'
      cmd_out <- execGRASS("v.info", map=res_vect, flags=c("c", "e"), intern=T)
      if (!any(grepl(cmd_out, pattern="\\|area"))) #add area column
      {  
        #ii: solve this directly in GRASS using v.to.db 
        res_lump <- readVECT(res_vect)
        projection(res_lump) <- getLocationProj()
        
        res_lump@data$t_id = 1:nrow(res_lump@data) #create temporary ID
        clean_temp_dir(res_vect)
        
        get.area <- function(polygon) {
          row <- data.frame(id=polygon@ID, area=polygon@area, stringsAsFactors=FALSE)
          return(row)
        }
        areas <- do.call(rbind,lapply(res_lump@polygons, get.area))
        res_lump@data  <- merge(res_lump@data, areas, by.x="t_id", by.y="id")  # append area column to plt.data
        res_lump@data$t_id = NULL #discard temporary ID
        res_lump@data$cat = NULL #discard internal GRASS ID that will be re-generated anyway
        writeVECT(SDF = res_lump, vname="t_t", v.in.ogr_flags=c("o","overwrite"))
        clean_temp_dir("t_t")
      } else #area column already present
        x <- execGRASS("g.copy", vector=paste(res_vect,"t_t", sep=","), flags="overwrite", intern=TRUE)           
                
      #convert polygons to points  
      x <- execGRASS("v.type", input="t_t", output=res_vect_classified, from_type="centroid", to_type="point", flags="overwrite", intern=TRUE) 
    
        if(!silent) message("% OK")
        
    } else #the input map is already a point map with the required columns, use it
    x <- execGRASS("g.copy", vector=paste(res_vect,res_vect_classified, sep=","), flags="overwrite", intern=TRUE)       
    
    
    
    # GROUP RESERVOIRS INTO SIZE CLASSES #-------------------------------------
    if(!silent) message("%")
    if(!silent) message("% Reservoir calculations...")
    
    #add subbasin-ID to reservoirs ####
    x <- execGRASS("v.db.addcolumn", map=res_vect_classified, columns="subbas_id int", intern=TRUE) 
    x <- execGRASS("v.what.rast", map=res_vect_classified, column="subbas_id", raster=subbas, intern=TRUE)  
    
    res_lump <- readVECT(res_vect_classified, type = "point") #re-load from GRASS
    clean_temp_dir(res_vect_classified)
    projection(res_lump) <- getLocationProj()
    
    # calculate parameter vol_max if not given
    if(is.null(res_param$vol_max)) {
      if(is.null(res_param$area_max)) {
        # area_max is also not given, i.e. calculate vol_max based on quantiles of sizes given in GRASS data
        res_lump <- readVECT(res_vect_classified, type="point")
        # WINDOWS PROBLEM: delete temporary file otherwise an error occurs when calling writeVECT or readVECT again with the same (or a similar) file name 
        if(.Platform$OS.type == "windows") {
          dir_del <- dirname(execGRASS("g.tempfile", pid=1, intern=TRUE, ignore.stderr=T))
          files_del <- grep(substr(res_vect_classified, 1, 8), dir(dir_del), value = T)
          if (length(files_del)>0)
            file.remove(paste(dir_del, files_del, sep="/"), showWarnings=FALSE)
        }
        if("volume" %in% ncols) {
          if (!"volume" %in% names(res_lump@data)) #no area column found
            stop("Column 'area' not found in generated vector '", res_vect_classified,"' something went wrong in the previous steps!") 
          quants <- quantile(res_lump@data[,"volume"], probs=c(.2,1))
          classes <- exp(approx(log(quants), n = length(res_param$class))$y)
          res_param$vol_max <- classes
          if("area" %in% ncols) {
            quants <- quantile(res_lump@data[,"area"], probs=c(.2,1))
            classes <- exp(approx(log(quants), n = length(res_param$class))$y)
            res_param$area_max <- classes
          } else
            res_param$area_max <- molle_a(res_param$alpha_Molle, res_param$damk_Molle, classes)
        } else {
          if (!"area" %in% names(res_lump@data)) #no area column found
            stop("Column 'area' not found in generated vector '", res_vect_classified,"' something went wrong in the previous steps!") 
          quants <- quantile(res_lump@data[,"area"], probs=c(.2,1))
          classes <- exp(approx(log(quants), n = length(res_param$class))$y)
          res_param$area_max <- classes
          res_param$vol_max <- molle_v(res_param$alpha_Molle, res_param$damk_Molle, res_param$area_max)
        }
        
      } else
        res_param$vol_max <- molle_v(res_param$alpha_Molle, res_param$damk_Molle, res_param$area_max)
    }
    
    # determine size class for each reservoir
    if("volume" %in% ncols)
      res_lump$size_class <- as.integer(cut(res_lump$volume, c(0, res_param$vol_max), labels=res_param$class))
    else 
      res_lump$size_class <- as.integer(cut(res_lump$area, c(0, res_param$area_max), labels=res_param$class))
    
    # calculate volume for reservoirs if it does not exist
    if((!"volume" %in% names(res_lump@data)))
      for(i in 1:nrow(res_lump))
        res_lump$volume[i] <- molle_v(res_param$alpha_Molle[res_lump$size_class[i]],
                                      res_param$damk_Molle[res_lump$size_class[i]],
                                      res_lump$area[i])
    
    # get information of maximum volume for each subbasin - size class combination
    lake_maxvol <- tapply(res_lump$volume, list(sub_id=res_lump$subbas_id, size_class=res_lump$size_class), max)
    lake_maxvol[which(is.na(lake_maxvol))] <- 0
    #add missing subbasins without small reservoirs, if any
    subbas_all <- execGRASS("r.stats", input=subbas, flags=c("n","quiet"), intern=TRUE) 
    sub_miss <- subbas_all[which(!(subbas_all %in% as.numeric(rownames(lake_maxvol))))]
    sub_miss <- matrix(0, nrow = length(sub_miss), ncol=nrow(res_param), dimnames = list(sub_miss, NULL))
    lake_maxvol <- rbind(lake_maxvol, sub_miss)
    lake_maxvol <- lake_maxvol[order(as.numeric(rownames(lake_maxvol))),]
    
    # get information of number of reservoirs for each subbasin - size class combination
    lake_number <- tapply(res_lump$volume, list(sub_id=res_lump$subbas_id, size_class=res_lump$size_class), length)
    lake_number[which(is.na(lake_number))] <- 0
    lake_number <- rbind(lake_number, sub_miss)
    lake_number <- lake_number[order(as.numeric(rownames(lake_number))),]
 
    if(!silent) message("% OK")
    
    
    
    # CREATE OUTPUT FILES #----------------------------------------------------
    if(!silent) message("%")
    if(!silent) message("% Create output files...")
    
    # res_vect_classified
    if(!is.null(res_vect_classified)) {
      writeVECT(SDF = res_lump, vname=res_vect_classified, v.in.ogr_flags=c("o","overwrite"))
      clean_temp_dir(res_vect_classified)
    }
    
    # reservoirs_small_classes_file from 'res_param'
    #write(file = paste(dir_out, reservoirs_small_classes_file, sep="/"), "Reservoir_class-ID, maxlake0[m**3], lake_vol0_factor[-], lake_change[-], alpha_Molle[-], damk_Molle[-], damc_hrr[-], damd_hrr[-]", append=F)
    dat_out <- res_param
    #rename columns
    names(dat_out)[names(dat_out)=="class"]="pid"  
    names(dat_out)[names(dat_out)=="vol_max"]="maxlake0"  
    names(dat_out)[names(dat_out)=="f_vol_init"]="lake_vol0_factor"  
    names(dat_out)[names(dat_out)=="class_change"]="lake_change"  
    names(dat_out)[names(dat_out)=="damk_Molle"]="k_Molle"  
    names(dat_out)[names(dat_out)=="damc_hrr"]="damc"  
    names(dat_out)[names(dat_out)=="damd_hrr"]="damd"  
    dat_out$name="" #optional
    
    # data.frame(pid=res_param$class, res_param$vol_max, res_param$f_vol_init, res_param$class_change,
    #                       res_param$alpha_Molle, res_param$damk_Molle, res_param$damc_hrr, res_param$damd_hrr)
    write.table(file = paste(dir_out, reservoirs_small_classes_file, sep="/"), format(dat_out, scientific=F), sep="\t", quote=F, append=F, row.names = F, col.names = T)
    
    # lake_number.dat from classified reservoirs
    dat_out = data.frame(subbas_id=row.names(lake_number), res_class_id=rep(dimnames(lake_number)[[2]], each=nrow(lake_number)),
               n_reservoirs=matrix(lake_number, ncol=1), maxlake=matrix(lake_maxvol, ncol=1))
    
    write.table(file=paste(dir_out, r_subbas_contains_reservoirs_small_file, sep="/"), dat_out, append=F, quote=F, sep="\t", row.names = F, col.names = T)
    
    
    # remove temporary maps
    if(keep_temp == FALSE)
      execGRASS("g.remove", type="raster,vector", pattern="*_t", flags=c("f"))
    
    
    if(!silent) message("% OK")
    if(!silent) message("%")
    if(!silent) message("% DONE!")
    if(!silent) message("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    
    # stop sinking
    closeAllConnections()
    
    # restore original warning mode
    if(silent)
      options(warn = oldw)
    
    
    
    
    # exception handling
  }, error = function(e) {
    
    
    # stop sinking
    closeAllConnections()
    
    # restore original warning mode
    if(silent)
      options(warn = oldw)
    
    # remove mask if there is any (and ignore error in case there is no mask)
    cmd_out <-tryCatch(suppressWarnings(execGRASS("r.mask", flags=c("r"), intern = T)), error=function(e){})
    
    if(keep_temp == FALSE)
      cmd_out <- execGRASS("g.remove", type="raster,vector", pattern=paste0("*_t,", res_vect_classified), flags=c("f", "b"), intern = T)
    
    stop(paste(e))  
  })
    
} # EOF
