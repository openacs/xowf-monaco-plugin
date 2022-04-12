::xo::library doc {
  Support for different kinds of tests and exercises using code interactions.
  
  @author Stefan Sobernig
}

::xo::library require -package xowf test-item-procs

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::code_interaction
  #
  ###########################################################

  Class create code_interaction -superclass TestItemField

  code_interaction instproc initialize {} {
    if {${:__state} ne "after_specs"} return
    #
    # Create component structure.
    #
    set widget [test_item set richtextWidget]

    if {${:auto_correct}} {
      set autoCorrectSpec {{correct_when {monaco,language=plaintext,label=#xowf.correct_when#}}}
    } else {
      set autoCorrectSpec ""
    }

    :create_components  [subst {
      {text  {$widget,label=#xowf.exercise-text#,plugins=OacsFs}}
      {language {text}}
      $autoCorrectSpec
    }]
    set :__initialized 1
  }

  code_interaction instproc convert_to_internal {} {
    set intro_text [:get_named_sub_component_value text]

    dict set fc_dict label #xowf.answer#

    # monaco-specific settings
    dict set fc_dict language [:get_named_sub_component_value language]
    dict set fc_dict minimap false

    if {${:auto_correct}} {
      dict set fc_dict correct_when [:get_named_sub_component_value correct_when]
    }

    append form \
        "<form>\n" \
        "<div class='code_interaction'>\n" \
        "<div class='question_text'>$intro_text</div>\n" \
        "@answer@\n" \
        "</div>\n" \
        "</form>\n"
    append fc \
        "@categories:off @cr_fields:hidden\n" \
        "{answer:[:dict_to_fc -type monaco $fc_dict]}"
    
    ns_log notice "code_interaction $form\n$fc"
    ${:object} set_property -new 1 form $form
    ${:object} set_property -new 1 form_constraints $fc
    set anon_instances true ;# TODO make me configurable
    ${:object} set_property -new 1 anon_instances $anon_instances
    ${:object} set_property -new 1 auto_correct ${:auto_correct}
    ${:object} set_property -new 1 has_solution false
  }
}

namespace eval ::xowf::monaco {
  ::xotcl::Class create test_item 
  test_item instproc initialize {} {
    if {${:__state} ne "after_specs"} {
      return
    }
    if {${:question_type} eq "ci"} {
      set options ""

      set interaction_class code_interaction
      set auto_correct ${:auto_correct}
      set can_shuffle false

      :log test_item-auto_correct=$auto_correct
      #
      # Handle feedback_level.
      #
      # The object might be a form, just use the property, if we are on
      # a FormPage.
      #
      if {[${:object} istype ::xowiki::FormPage]} {
        set feedback_level_property [${:object} property feedback_level]
        if {$feedback_level_property ne ""} {
          set :feedback_level $feedback_level_property
        }
      }

      if {${:grading} ne "none"} {
        if {${:grading} ni {exact partial}} {
          error "invalid grading '$grading'; valid are 'exact' or 'partial'"
        }
        set options "{exact exact} {partial partial}"
        set gradingSpec [subst {grading {select,options=$options,default=${:grading},label=#xowf.Grading-Scheme#}}]
      } else {
        set gradingSpec ""
      }

      if {$can_shuffle} {
        set shuffle_options "{#xowf.shuffle_none# none} {#xowf.shuffle_peruser# peruser} {#xowf.shuffle_always# always}"
        set shuffleSpec [subst {
          {shuffle {radio,horizontal=true,form_item_wrapper_CSSclass=form-inline,options=$shuffle_options,default=none,label=#xowf.Shuffle#}}
          {show_max {number,form_item_wrapper_CSSclass=form-inline,min=2,label=#xowf.show_max#}}
        }]
      } else {
        set shuffleSpec ""
      }
      :create_components  [subst {
        {minutes number,min=1,default=2,label=#xowf.Minutes#}
        $gradingSpec
        $shuffleSpec
        {interaction {$interaction_class,$options,feedback_level=${:feedback_level},auto_correct=${:auto_correct},label=}}
        [:feedback_definition]
      }]
      set :__initialized 1
    } else {
      next
    }
  }
 
  ::xowiki::formfield::test_item instmixin add test_item
}

::xo::library source_dependent
#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    eval: (setq tcl-type-alist (remove* "method" tcl-type-alist :test 'equal :key 'car))
#    indent-tabs-mode: nil
# End:
