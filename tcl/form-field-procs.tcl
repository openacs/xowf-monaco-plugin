::xo::library doc {
  Form field definition for Monaco Editor

  @author Stefan Sobernig
}

:::xo::db::require package xowiki


namespace eval ::xowiki::formfield {

  ########################################################s###
  #
  # ::xowiki::formfield::monaco
  #
  ###########################################################

  Class create monaco -superclass FormField -parameter {
    {language "tcl"}
    {theme "vs"}
    {width 800px}
    {height 600px}
    {minimap true}
    {CSSclass xowf-monaco-container}
    {readOnly false}
  }

  # TODO: Provide for switching between debug (dev) and production (min) mode
  monaco instproc initialize {} {
    if {![info exists :__initialized]} {
      # TODO: Provide for setting data attributes (data-name) on link
      # tags via template::head::add_link
      ::xo::Page requireJS urn:ad:js:jquery

      # TODO: Switch to URN, once template::head::add_link (see above) is supported
      ::xo::Page requireJS {
        $("<link/>", {
          rel: "stylesheet",
          type: "text/css"
        }).attr("data-name", "vs/editor/editor.main")
        .attr("href","/resources/xowf-monaco-plugin/monaco-editor/min/vs/editor/editor.main.css")
        .appendTo("head");
      }

      #::xo::Page requireCSS "/resources/xowf-monaco-plugin/plugin.css"
      ::xo::Page requireCSS urn:ad:css:monaco:plugin
      #::xo::Page requireJS "/resources/xowf-monaco-plugin/plugin.js"
      ::xo::Page requireJS  urn:ad:js:monaco:plugin
      
      set :__initialized 1
    }
  }

  monaco instproc fromBase64 {encValue} {
    # this is the equivalent to b64_to_utf8 at the client side
    if {$encValue ne ""} {
      return [encoding convertfrom utf-8 [binary decode base64 $encValue]]
    }
  }

  monaco instproc pretty_value {v} {
    return [:fromBase64 [:value]]
  }

  monaco instproc render_input {} {
    # TODO: Find the appropriate CSP escapes for monaco
    security::csp::require script-src 'unsafe-inline'
    
    set isDisabled [:is_disabled]

    if {!$isDisabled} {
      append :style "width: ${:width};" "height: ${:height};"
    } else {
      lappend :CSSclass "disabled"
    }

    ::html::div [:get_attributes id style {CSSclass class}] {}
    
    template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
    template::add_body_script -src urn:ad:js:monaco:min/vs/loader
    template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main.nls
    template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main

    # TODO: Use ids accepted by JQuery
    # regsub -all {[.:]} ${:id} "" id
    set currentValue [:value]

    if {!$isDisabled} {
      template::add_body_script -script [subst -nocommands {
      
        xowf.monaco.editors.push(monaco.editor.create(document.getElementById('${:id}'), {
          language: '${:language}', minimap: {enabled: ${:minimap}}, readOnly: ${:readOnly}, theme: '${:theme}'
      }));
        xowf.monaco.editors[xowf.monaco.editors.length-1].setValue(xowf.monaco.b64_to_utf8('$currentValue'));
        
      }]

      if {!${:readOnly}} {
        ::html::input -type hidden -name ${:name} -id ${:id}.hidden
        template::add_body_script -script {
          $(document).ready(function(){
            $("form").submit(function(event) {
              for (var i = 0; i < xowf.monaco.editors.length ; i++)  {
               var e = xowf.monaco.editors[i];
               if (!e.getRawOptions()["readOnly"]) {
                 var hiddenId = e.getDomNode().parentNode.id + ".hidden";
                 var hiddenEl = document.getElementById(hiddenId);
                 if (hiddenEl != null) {
                   hiddenEl.value = xowf.monaco.utf8_to_b64(e.getValue());
                 }
               }                             
             }
            });
          });
        }
      }
    } else {
      template::add_body_script -script [subst {
        monaco.editor.colorize(xowf.monaco.b64_to_utf8('$currentValue'), '${:language}')
        .then(html => document.getElementById('${:id}').innerHTML = html);
      }]
    }
  }

  monaco instproc set_feedback {feedback_mode} {
    next
  }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
