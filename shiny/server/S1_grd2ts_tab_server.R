#---------------------------------------------------------------------------
# Folder processing
output$s1_g2ts_inputfolder = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2ts_inputdir', roots=volumes)
  
  validate (
    need(input$s1_g2ts_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2ts_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Inventory file
output$s1_g2ts_shp_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_g2ts_shp', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$s1_g2ts_shp != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  df = parseFilePaths(volumes, input$s1_g2ts_shp)
  s1_g2ts_shp_file_path = as.character(df[,"datapath"])
  cat(s1_g2ts_shp_file_path)
})

# output folder 
output$s1_g2ts_outfolder = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2ts_outdir', roots=volumes)
  
  validate (
    need(input$s1_g2ts_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2ts_outdir)
  cat(df) #}
})


#---------------------------------------------------------------------------
# Zip file
# output folder 
output$s1_g2ts_outfolder2 = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2ts_outdir2', roots=volumes)
  
  validate (
    need(input$s1_g2ts_outdir2 != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2ts_outdir2)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing functions
print_s1_g2ts = eventReactive(input$s1_g2ts_process, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_g2ts_process", {
    
    volumes = c('User directory'=Sys.getenv("HOME"))
  
  if (input$s1_g2ts_input_type == "folder"){

    if(is.null(input$s1_g2ts_inputdir)){
      stop("No output folder chosen")
    }
  
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      OUTDIR = parseDirPath(volumes, input$s1_g2ts_inputdir)
    
      if (input$s1_g2ts_res == "med_res"){
        MODE = "MED_RES" 
      } 
    
      else if (input$s1_inv_pol == "full_res"){
        MODE = "HI_RES" 
      }
    
      s1_g2ts_message="Processing started (This will take a while.)"
      js_string_s1_g2ts <- 'alert("Processing");'
      js_string_s1_g2ts <- sub("Processing",s1_g2ts_message,js_string_s1_g2ts)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts))

      ARG_PROC=paste(OUTDIR, MODE, "1")
      print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
      system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    
      s1_g2ts_fin_message="Processing finished"
      js_string_s1_g2ts_fin <- 'alert("Processing");'
      js_string_s1_g2ts_fin <- sub("Processing",s1_g2ts_fin_message,js_string_s1_g2ts_fin)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts_fin))
    } 
  } 
  
  else if (input$s1_g2ts_input_type == "inventory"){
  
    if(is.null(input$s1_g2ts_shp)){
      stop("No S1 inputfile chosen")
    } 
  
    else if(is.null(input$s1_g2ts_outdir)){
      stop("No output folder chosen")
    }
  
    else {
    
      # download
      df = parseFilePaths(volumes, input$s1_g2ts_shp)
      INFILE = as.character(df[,"datapath"])
    
      volumes = c('User directory'=Sys.getenv("HOME"))
      OUTDIR = parseDirPath(volumes, input$s1_g2ts_outdir)
    
      # handling username and password data
      UNAME = paste("http_user=",input$s1_asf_uname2, sep = "")
      PW = paste("http_password=",input$s1_asf_piwo2,sep="")
      HOME_DIR = Sys.getenv("HOME")
      FILE = file.path(HOME_DIR,"wget.conf")
      write(UNAME, FILE)
      write(PW, FILE, append = TRUE)
      rm(UNAME)
      rm(PW)
      system("echo $USER", intern=FALSE)
      system(paste("chmod 600",FILE), intern=TRUE)
    
      ARG_DOWN=paste(OUTDIR, INFILE, FILE)
      print(paste("oft-sar-S1-ASF-download", ARG_DOWN))
      s1_g2ts_start_message="Started downloading (this will take a few hours)"
      s1_g2ts_js_string <- 'alert("Downloading");'
      s1_g2ts_js_string <- sub("Downloading",s1_g2ts_start_message,s1_g2ts_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2ts_js_string))
      system(paste("oft-sar-S1-ASF-download", ARG_DOWN),intern=TRUE)
      unlink(FILE)
    
      # processing
      if (input$s1_g2ts_res == "med_res"){
        MODE = "MED_RES" 
      } 
    
      else if (input$s1_inv_pol == "full_res"){
        MODE = "HI_RES" 
      }
    
      s1_g2ts_message="Download is finished. Starting to process (This will take a while.)"
      js_string_s1_g2ts <- 'alert("Processing");'
      js_string_s1_g2ts <- sub("Processing",s1_g2ts_message,js_string_s1_g2ts)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts))
      
      OUTDIR_DATA = paste(OUTDIR,"/DATA",sep="")
      ARG_PROC=paste(OUTDIR_DATA, MODE, "1")
      print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
      system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    
      s1_g2ts_fin_message="Processing finished"
      js_string_s1_g2ts_fin <- 'alert("Processing");'
      js_string_s1_g2ts_fin <- sub("Processing",s1_g2ts_fin_message,js_string_s1_g2ts_fin)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts_fin))
    } 
  }
  
  else if (input$s1_g2ts_input_type == "s1_g2ts_zipfile"){
  
    if(is.null(input$S1_g2ts_zipfile_path)){
      stop("No zip archive chosen")
    } 
  
    else if(is.null(input$s1_g2ts_outdir2)){
      stop("No output folder chosen")
    }
  
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      OUTDIR = parseDirPath(volumes, input$s1_g2ts_outdir2)
    
      df = input$S1_g2ts_zipfile_path
      ARCHIVE = df$datapath
      OUT_ARCHIVE = paste(OUTDIR, "/Inventory_upload", sep = "")
      dir.create(OUT_ARCHIVE)
      unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
      OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
      INFILE = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
    
      # handling username and password data
      UNAME = paste("http_user=",input$s1_asf_uname2, sep = "")
      PW = paste("http_password=",input$s1_asf_piwo2,sep="")
      HOME_DIR = Sys.getenv("HOME")
      FILE = file.path(HOME_DIR,"wget.conf")
      write(UNAME, FILE)
      write(PW, FILE, append = TRUE)
      rm(UNAME)
      rm(PW)
      system("echo $USER", intern=FALSE)
      system(paste("chmod 600",FILE), intern=TRUE)
    
      ARG_DOWN=paste(OUTDIR, INFILE, FILE)
      print(paste("oft-sar-S1-ASF-download", ARG_DOWN))
      s1_g2ts_start_message="Started downloading (this will take a few hours)"
      s1_g2ts_js_string <- 'alert("Downloading");'
      s1_g2ts_js_string <- sub("Downloading",s1_g2ts_start_message,s1_g2ts_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2ts_js_string))
      system(paste("oft-sar-S1-ASF-download", ARG_DOWN),intern=TRUE)
      unlink(FILE)

      # processing
      if (input$s1_g2ts_res == "med_res"){
        MODE = "MED_RES" 
      } 
    
      else if (input$s1_inv_pol == "full_res"){
        MODE = "HI_RES" 
      }
    
      OUTDIR_DATA = paste(OUTDIR,"/DATA",sep="")
      ARG_PROC=paste(OUTDIR_DATA, MODE, "1")
      
      s1_g2ts_message="Download is finished. Starting to process (This will take a while.)"
      js_string_s1_g2ts <- 'alert("Processing");'
      js_string_s1_g2ts <- sub("Processing",s1_g2ts_message,js_string_s1_g2ts)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts))
    
      print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
      system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    
      s1_g2ts_fin_message="Processing finished"
      js_string_s1_g2ts_fin <- 'alert("Processing");'
      js_string_s1_g2ts_fin <- sub("Processing",s1_g2ts_fin_message,js_string_s1_g2ts_fin)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts_fin))
    
    }
  }
  })
})


output$processS1_G2TS = renderText({
  print_s1_g2ts()
})