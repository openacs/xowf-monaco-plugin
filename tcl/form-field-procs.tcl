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

  ########################################################s###
  #
  # ::xowiki::formfield::html_sandbox
  #
  ###########################################################

  Class create html_sandbox -superclass monaco -ad_doc {
    This class provides a HTML sandbox formfield powered by the Monaco
    code editor set to HTML mode. The code inputed in the editor is
    rendered as a standalone document inside an iframe.

    The formfield also supports live preview, updated whenever the
    code has changed.
  } -parameter {
    {preview true}
  }

  html_sandbox instproc initialize args {
    set :language html
    next
  }

  html_sandbox ad_instproc render_input args {
    Displays the editor. If user selected to have the preview, will
    put editor and preview side by side using flexbox responsive
    layout. The preview will update automatically whenever the code
    changes.
  } {
    # No preview, just show the editor
    if {!${:preview}} {
      return [next]
    }

    ::html::div -id ${:id}-container style "display:flex; flex-wrap:wrap;" {
      ::html::div -id ${:id}-code {
        next
      }
      ::html::div -id ${:id}-preview {
        ::html::iframe -id ${:id}-iframe -style "width: ${:width}; height: ${:height};"
      }
    }

    # Find our Monaco editor instance, get its value and inject it
    # into the preview iframe. Listen also to any change and update
    # the preview on the fly.
    template::add_body_handler -event load -script [subst -nocommands {
      var iframe = document.getElementById('${:id}-iframe');
      for (var i = 0; i < xowf.monaco.editors.length ; i++)  {
        var e = xowf.monaco.editors[i];
        if (!e.getRawOptions()["readOnly"]) {
          var hiddenId = e.getDomNode().parentNode.id + ".hidden";
          if (hiddenId === '${:id}.hidden') {
            // This is our editor, set its value in the iframe
            iframe.srcdoc = e.getValue();
            // Listen to changes and update the iframe
            e.onDidChangeModelContent((event) => {
              iframe.srcdoc = e.getValue();
            });
          }
        }
      }
    }]
  }

  html_sandbox ad_instproc pretty_value args {
    Put the code (base64 encoded) in an invisible template element and
    add an iframe. When the page loads, translate and put the code
    inside the template element as the document of the iframe, so that
    it is rendered.

    @return HTML
  } {
    template::add_body_handler -event load -script [subst -nocommands {
      var srcDoc = document.getElementById('${:id}-srcdoc');
      var iframe = document.getElementById('${:id}-iframe');
      iframe.srcdoc = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);
    }]
    set base64 [:value]
    return [subst -nocommands {
      <template id="${:id}-srcdoc" style="display:none;">$base64</template>
      <iframe style="width: ${:width}; height: ${:height};" id="${:id}-iframe"></iframe>
    }]
  }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
