*&---------------------------------------------------------------------*
*& Report Y234_MATERIAL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT y234_material.

***Selection Screen***
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS : p_file TYPE ibipparms-path,
               p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

TYPES : BEGIN OF ty_material,
          industry_sector  TYPE mbrsh,
          material_type    TYPE mtart,
          plant            TYPE werks_d,
          storage_loc      TYPE lgort_d,
          description      TYPE maktx,
          unit_of_measure  TYPE meins,
          material_grp     TYPE matkl,
          no_link          TYPE char1,
          purchasing_grp   TYPE ekgrp,
          mrp_type         TYPE dismm,
          lot_size         TYPE disls,
          reorder_point    TYPE minbe,
          mrp_controller   TYPE dispo,
          max_stock_level  TYPE mabst,
          availability_chk TYPE mtvfp,
          period_indicator TYPE dattp,
        END OF ty_material,
        tty_material TYPE TABLE OF ty_material,
        BEGIN OF ty_log,
          status(4)       TYPE c,
          message         TYPE string,
          material        TYPE matnr,
          description     TYPE maktx,
          plant           TYPE werks_d,
          storage_loc     TYPE lgort_d,
          industry_sector TYPE mbrsh,
          material_type   TYPE mtart,
          material_grp    TYPE matkl,
          purchasing_grp  TYPE ekgrp,
        END OF ty_log,
        tty_log TYPE TABLE OF ty_log.

DATA : gt_material TYPE TABLE OF ty_material,
       gt_log      TYPE TABLE OF ty_log.

CLASS ycl_material DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS : get_filename.
    METHODS : get_filedata CHANGING ct_material TYPE tty_material,
      get_validations  CHANGING ct_material TYPE tty_material
                                ct_log      TYPE tty_log,
      fetch_material IMPORTING it_material TYPE tty_material
                     CHANGING  ct_log      TYPE tty_log,
      alv_display CHANGING ct_log TYPE tty_log,
      met_material FOR EVENT link_click OF cl_salv_events_table IMPORTING row column.
ENDCLASS.
CLASS ycl_material IMPLEMENTATION.
  METHOD get_filename.
    CALL FUNCTION 'F4_FILENAME'
      EXPORTING
        program_name  = syst-cprog
        dynpro_number = syst-dynnr
      IMPORTING
        file_name     = p_file.
  ENDMETHOD.
  METHOD get_filedata.
    DATA : lt_alsm     TYPE STANDARD TABLE OF alsmex_tabline,
           ls_material TYPE ty_material.

    FIELD-SYMBOLS : <lfs_material> TYPE ty_material.
***Excel to internal table****

    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        filename                = p_file
        i_begin_col             = 1
        i_begin_row             = 2
        i_end_col               = 20
        i_end_row               = 100
      TABLES
        intern                  = lt_alsm
      EXCEPTIONS
        inconsistent_parameters = 1
        upload_ole              = 2
        OTHERS                  = 3.

    IF sy-subrc <> 0.
      MESSAGE 'File Open Error' TYPE 'S' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

*Fill Excel Table to Material Internal Table
    LOOP AT lt_alsm INTO DATA(ls_alsm).
***Fill the data****
      ASSIGN COMPONENT ls_alsm-col OF STRUCTURE ls_material TO FIELD-SYMBOL(<lfs_value>).
      IF <lfs_value> IS ASSIGNED.
        <lfs_value> = ls_alsm-value.
      ENDIF.

      AT END OF row.
        APPEND ls_material TO ct_material.
        CLEAR ls_material.
      ENDAT.
    ENDLOOP.
  ENDMETHOD.
  METHOD get_validations.
    DATA : lv_tabix   TYPE sy-tabix,
           lv_flag(1) TYPE c,
           lv_message TYPE string.

***Industry Sector***
    SELECT mbrsh
      FROM t137
   FOR ALL ENTRIES IN @gt_material
     WHERE mbrsh = @gt_material-industry_sector
      INTO TABLE @DATA(lt_ind_sec).

***Material Type***
    SELECT mtart
      FROM t134
   FOR ALL ENTRIES IN @gt_material
     WHERE mtart = @gt_material-material_type
      INTO TABLE @DATA(lt_mat_type).

***Plant***
    SELECT werks
      FROM t001w
   FOR ALL ENTRIES IN @gt_material
     WHERE werks = @gt_material-plant
      INTO TABLE @DATA(lt_plant).

***Storage Location***
    SELECT lgort
      FROM t001l
   FOR ALL ENTRIES IN @gt_material
     WHERE lgort = @gt_material-storage_loc
      INTO TABLE @DATA(lt_sto_loc).

***Material Group***
    SELECT matkl
      FROM t023
   FOR ALL ENTRIES IN @gt_material
     WHERE matkl = @gt_material-material_grp
      INTO TABLE @DATA(lt_mat_grp).

***Purchasing Group***
    SELECT ekgrp
      FROM t024
   FOR ALL ENTRIES IN @gt_material
     WHERE ekgrp = @gt_material-purchasing_grp
      INTO TABLE @DATA(lt_pur_grp).
***Validations the values based on user entery***
    LOOP AT ct_material INTO DATA(ls_material).
      lv_tabix = sy-tabix.

      READ TABLE lt_ind_sec INTO DATA(ls_ind_sec) WITH KEY mbrsh = ls_material-industry_sector.
      IF sy-subrc <> 0.
        lv_flag = 'X'.
        lv_message = 'Please Enter Valid Industry Sector'.
      ENDIF.

      READ TABLE lt_mat_type INTO DATA(ls_mat_type) WITH KEY mtart = ls_material-material_type.
      IF sy-subrc <> 0.
        lv_flag = 'X'.
        lv_message = 'Please Enter Valid Material Type'.
      ENDIF.

      READ TABLE lt_plant INTO DATA(ls_plant) WITH KEY werks = ls_material-plant.
      IF sy-subrc <> 0.
        lv_flag = 'X'.
        lv_message = 'Please Enter Valid Plant'.
      ENDIF.

      READ TABLE lt_sto_loc INTO DATA(ls_sto_loc) WITH KEY lgort = ls_material-storage_loc.
      IF sy-subrc <> 0.
        lv_flag = 'X'.
        lv_message = 'Please Enter Valid Storage Location'.
      ENDIF.

      READ TABLE lt_mat_grp INTO DATA(ls_mat_grp) WITH KEY matkl = ls_material-material_grp.
      IF sy-subrc <> 0.
        lv_flag = 'X'.
        lv_message = 'Please Enter Valid Material Group'.
      ENDIF.

      READ TABLE lt_pur_grp INTO DATA(ls_pur_grp) WITH KEY ekgrp = ls_material-purchasing_grp.
      IF sy-subrc <> 0.
        lv_flag = 'X'.
        lv_message = 'Please Enter Valid Purchasing Group'.
      ENDIF.

      IF lv_flag = 'X'.
        ct_log = VALUE #( BASE gt_log ( status          = icon_red_light
                                        message         = lv_message
                                        plant           = ls_material-plant
                                        storage_loc     = ls_material-storage_loc
                                        industry_sector = ls_material-industry_sector
                                        material_type   = ls_material-material_type
                                        material_grp    = ls_material-material_grp
                                        purchasing_grp  = ls_material-purchasing_grp ) ).
        DELETE ct_material INDEX lv_tabix.
      ENDIF.
      CLEAR : lv_flag,lv_message.
    ENDLOOP.
  ENDMETHOD.
  METHOD fetch_material.

    DATA : ls_header      TYPE bapimathead,
           ls_plantdata   TYPE bapi_marc,
           ls_plantdatax  TYPE bapi_marcx,
           lt_mat         TYPE TABLE OF bapi_makt,
           ls_clientdata  TYPE bapi_mara,
           ls_clientdatax TYPE bapi_marax,
           ls_sto_data    TYPE bapi_mard,
           ls_sto_datax   TYPE bapi_mardx,
           ls_return_num  TYPE bapireturn1,
           ls_return      TYPE bapiret2,
           lt_return      TYPE TABLE OF bapi_matreturn2.

    DATA : lt_matnr_num TYPE TABLE OF bapimatinr,
           lv_matnr     TYPE matnr,
           lv_message   TYPE string,
           lv_material  TYPE matnr.

    LOOP AT it_material INTO DATA(ls_material).

***Get the material number***
      CALL FUNCTION 'BAPI_STDMATERIAL_GETINTNUMBER'
        EXPORTING
          material_type    = ls_material-material_type
          industry_sector  = ls_material-industry_sector
          required_numbers = 1
        IMPORTING
          return           = ls_return_num
        TABLES
          material_number  = lt_matnr_num.


      IF lt_matnr_num[] IS NOT INITIAL.
***Read the material***
        READ TABLE lt_matnr_num INTO DATA(ls_matnr_num) INDEX 1.
        IF sy-subrc = 0.
          lv_matnr = ls_matnr_num-material.
        ENDIF.
      ENDIF.
***Header data***
      ls_header-material = lv_matnr.
      ls_header-ind_sector = ls_material-industry_sector.
      ls_header-matl_type = ls_material-material_type.
      lt_mat = VALUE #( BASE lt_mat ( matl_desc = ls_material-description langu     = 'E') ).
***  clientdata***
      ls_clientdata-matl_group = ls_material-material_grp.
      ls_clientdata-base_uom = ls_material-unit_of_measure.
*** clientdatax**
      ls_clientdatax-matl_group = 'X'.
      ls_clientdatax-base_uom = 'X'.
*** plantdata**
      ls_plantdata-plant = ls_material-plant.
      ls_plantdata-pur_group = ls_material-purchasing_grp.
      ls_plantdata-mrp_type = ls_material-mrp_type.
      ls_plantdata-mrp_ctrler = ls_material-mrp_controller.
**** Converstion ***

      ls_plantdata-availcheck = |{ ls_material-availability_chk ALPHA = IN }|.
      ls_plantdata-lotsizekey = ls_material-lot_size.
      ls_plantdata-reorder_pt = ls_material-reorder_point.
      ls_plantdata-max_stock = ls_material-max_stock_level.
***  plantdatax**
      ls_plantdatax-plant = ls_material-plant.
****storagelocationdata**
      ls_sto_data-plant = ls_material-plant.
      ls_sto_data-stge_loc = ls_material-storage_loc.
***storagelocationdatax**
      ls_sto_datax-plant = ls_material-plant.
      ls_sto_datax-stge_loc = ls_material-storage_loc.

***Save data for material***
      CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
        EXPORTING
          headdata             = ls_header
          clientdata           = ls_clientdata
          clientdatax          = ls_clientdatax
          plantdata            = ls_plantdata
          plantdatax           = ls_plantdatax
*         FORECASTPARAMETERS   =
*         FORECASTPARAMETERSX  =
*         PLANNINGDATA         =
*         PLANNINGDATAX        =
          storagelocationdata  = ls_sto_data
          storagelocationdatax = ls_sto_datax
*         VALUATIONDATA        =
*         VALUATIONDATAX       =
*         WAREHOUSENUMBERDATA  =
*         WAREHOUSENUMBERDATAX =
*         SALESDATA            =
*         SALESDATAX           =
*         STORAGETYPEDATA      =
*         STORAGETYPEDATAX     =
*         FLAG_ONLINE          = ' '
*         FLAG_CAD_CALL        = ' '
*         NO_DEQUEUE           = ' '
*         NO_ROLLBACK_WORK     = ' '
        IMPORTING
          return               = ls_return
        TABLES
          materialdescription  = lt_mat
*         unitsofmeasure       =
*         unitsofmeasurex      =
*         INTERNATIONALARTNOS  =
*         MATERIALLONGTEXT     =
*         TAXCLASSIFICATIONS   =
          returnmessages       = lt_return
*         PRTDATA              =
*         PRTDATAX             =
*         EXTENSIONIN          =
*         EXTENSIONINX         =
        .
*** Read Return meassages***
      READ TABLE lt_return INTO DATA(ls_return_temp) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        LOOP AT lt_return INTO ls_return_temp WHERE type = 'E'.
          IF lv_message IS INITIAL.
            lv_message =  ls_return_temp-id && ls_return_temp-number && ls_return_temp-message .
          ELSE.
            lv_message =  lv_message &&  '|' && ls_return_temp-id && ls_return_temp-number && ls_return_temp-message .
          ENDIF.
        ENDLOOP.
        ct_log = VALUE #( BASE gt_log ( status          = icon_red_light
                                        message         = lv_message
                                        description     = ls_material-description
                                        plant           = ls_material-plant
                                        storage_loc     = ls_material-storage_loc
                                        industry_sector = ls_material-industry_sector
                                        material_type   = ls_material-material_type
                                        material_grp    = ls_material-material_grp
                                        purchasing_grp  = ls_material-purchasing_grp ) ).
      ELSE.
***Update the database***
        IF p_test IS INITIAL.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = abap_true.
          lv_message = 'Material Created Successfully'.
          IF ls_return-type = 'S'.
            lv_material = ls_return-message_v1.
          ENDIF.
        ELSE.
***Reuse the material number***
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          lv_message = 'Successful  No Errors'.
        ENDIF.
        ct_log = VALUE #( BASE gt_log ( status          = icon_green_light
                                        message         = lv_message
                                        material        = lv_material
                                        description     = ls_material-description
                                        plant           = ls_material-plant
                                        storage_loc     = ls_material-storage_loc
                                        industry_sector = ls_material-industry_sector
                                        material_type   = ls_material-material_type
                                        material_grp    = ls_material-material_grp
                                        purchasing_grp  = ls_material-purchasing_grp ) ).
      ENDIF.
      CLEAR : ls_header,ls_return,lt_return,
              lt_mat,ls_clientdata,ls_clientdatax,
              lt_matnr_num,ls_return_num,
              lv_message.
    ENDLOOP.

  ENDMETHOD.
  METHOD alv_display.

    DATA : lo_alv       TYPE REF TO cl_salv_table,
           lo_columns   TYPE REF TO cl_salv_columns,
           lo_sort      TYPE REF TO cl_salv_sorts,
           lo_column    TYPE REF TO cl_salv_column_table,
           lo_layout    TYPE REF TO cl_salv_layout,
           lo_key       TYPE salv_s_layout_key,
           lo_functions TYPE REF TO cl_salv_functions_list,
           lo_material  TYPE REF TO ycl_material.

***Display Final Table***
    TRY.
        CALL METHOD cl_salv_table=>factory
          EXPORTING
            list_display = if_salv_c_bool_sap=>false
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = ct_log.
      CATCH cx_salv_msg.
    ENDTRY.

    lo_layout     = lo_alv->get_layout( ).
    lo_key-report = sy-repid.
    lo_layout->set_key( lo_key ).
    lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

    lo_functions = lo_alv->get_functions( ).
    lo_functions->set_all( ).
***Get Columns***
    lo_columns = lo_alv->get_columns( ).
    lo_columns->set_optimize( abap_true ).

    TRY.
        lo_column ?= lo_columns->get_column( 'STATUS'  ).
        lo_column->set_icon( if_salv_c_bool_sap=>true ).
        lo_column->set_long_text( 'Status' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'MESSAGE'  ).
        lo_column->set_long_text( 'Message' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'MATERIAL'  ).
        lo_column->set_long_text( 'Material' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
*** Hotspot***
        lo_column->set_cell_type(
            value = if_salv_c_cell_type=>hotspot
        ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'DESCRIPTION'  ).
        lo_column->set_long_text( 'Description' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'PLANT'  ).
        lo_column->set_long_text( 'Plant' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'STORAGE_LOC'  ).
        lo_column->set_long_text( 'Storage Location' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'INDUSTRY_SECTOR'  ).
        lo_column->set_long_text( 'Industry Sector' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'MATERIAL_TYPE'  ).
        lo_column->set_long_text( 'Material Type' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'MATERIAL_GRP'  ).
        lo_column->set_long_text( 'Material Group' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    TRY.
        lo_column ?= lo_columns->get_column( 'PURCHASING_GRP'  ).
        lo_column->set_long_text( 'Purchasing Group' ).
        lo_column->set_short_text( '' ).
        lo_column->set_medium_text( '' ).
      CATCH cx_salv_not_found.
    ENDTRY.
    CREATE OBJECT lo_material.

    SET HANDLER lo_material->met_material FOR ALL INSTANCES.
    lo_alv->display( ).
  ENDMETHOD.
  METHOD met_material.
**** Call Transaction***
    CASE column.
      WHEN 'MATERIAL'.
        READ TABLE gt_log INTO DATA(ls_log) INDEX row.
        IF sy-subrc = 0 AND ls_log-material IS NOT INITIAL.
          SET PARAMETER ID 'MAT' FIELD ls_log-material.
          CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  CALL METHOD ycl_material=>get_filename.

START-OF-SELECTION.
**Create Object**
  DATA : lo_material TYPE REF TO ycl_material.

  CREATE OBJECT lo_material.
**Internal table Data***
  CALL METHOD lo_material->get_filedata
    CHANGING
      ct_material = gt_material.

  IF gt_material IS INITIAL.
    MESSAGE 'No Data Found' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ELSE.
**Validate Excel Data with Tables data**
    CALL METHOD lo_material->get_validations
      CHANGING
        ct_material = gt_material
        ct_log      = gt_log.
  ENDIF.

***Create Material***
  CALL METHOD lo_material->fetch_material
    EXPORTING
      it_material = gt_material
    CHANGING
      ct_log      = gt_log.

*Display Final Log Table
  CALL METHOD lo_material->alv_display
    CHANGING
      ct_log = gt_log.
