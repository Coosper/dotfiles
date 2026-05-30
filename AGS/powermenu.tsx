import app from "ags/gtk4/app"
import { Astal } from "ags/gtk4"
import { createState, With } from "ags"
import Gtk from "gi://Gtk"
import Gdk from "gi://Gdk"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

type Action = {
  label:  string
  key:    string
  icon:   string
  cmd:    string[]
  accent: string
}

const dir = `/home/${GLib.get_user_name()}/.dotfiles/AGS`

const actions: Action[] = [
  { label: "Shutdown", key: "s", icon: "⏻", cmd: [`${dir}/LogicScripts/shutdown`], accent: "pm-btn-red"   },
  { label: "Reboot",   key: "r", icon: "↺", cmd: [`${dir}/LogicScripts/restart`],  accent: "pm-btn-peach" },
  { label: "Log Out",  key: "l", icon: "⇥", cmd: ["loginctl", "kill-session", "self"], accent: "pm-btn-blue"  },
]

const [ok, bytes] = GLib.file_get_contents(`${dir}/powermenu.css`)
if (!ok) throw new Error("Could not load powermenu.css")
const css = new TextDecoder().decode(bytes)

function ConfirmView({ action, onConfirm, onCancel }: {
  action:    Action
  onConfirm: () => void
  onCancel:  () => void
}) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["pm-confirm-box"]} spacing={12}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
        <label label={`${action.icon}  ${action.label}`} cssClasses={["pm-confirm-action"]} halign={Gtk.Align.START} />
        <label label="are you sure?" cssClasses={["pm-confirm-sub"]} halign={Gtk.Align.START} />
      </box>
      <box spacing={8}>
        <button cssClasses={["pm-yes"]} onClicked={onConfirm}>
          <label label="yes" />
        </button>
        <button cssClasses={["pm-no"]} onClicked={onCancel}>
          <label label="cancel" />
        </button>
      </box>
    </box>
  )
}

function ActionList({ onSelect }: { onSelect: (a: Action) => void }) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL}>
      {actions.map((a) => (
        <button cssClasses={["pm-btn", a.accent]} onClicked={() => onSelect(a)}>
          <box orientation={Gtk.Orientation.HORIZONTAL} spacing={12}>
            <label cssClasses={["pm-btn-icon"]} label={a.icon} />
            <label cssClasses={["pm-btn-label"]} label={a.label} xalign={0} hexpand />
            <label cssClasses={["pm-btn-key"]} label={`[${a.key}]`} />
          </box>
        </button>
      ))}
    </box>
  )
}

app.start({
  css,
  main() {
    const [confirming, setConfirming] = createState<Action | null>(null)

    let timeoutId: number | null = null

    function scheduleAutoclose() {
      timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 30, () => {
        app.quit()
        return GLib.SOURCE_REMOVE
      })
    }

    function resetTimeout() {
      if (timeoutId !== null) GLib.source_remove(timeoutId)
      scheduleAutoclose()
    }

    function quit() {
      if (timeoutId !== null) GLib.source_remove(timeoutId)
      app.quit()
    }

    function selectAction(a: Action) {
      resetTimeout()
      setConfirming(a)
    }

    function cancelConfirm() {
      resetTimeout()
      setConfirming(null)
    }

function runAndQuit(a: Action) {
  console.log("runAndQuit called, cmd:", a.cmd)
  try {
    const proc = Gio.Subprocess.new(a.cmd, Gio.SubprocessFlags.NONE)
    console.log("subprocess spawned:", proc)
  } catch (e) {
    console.error(`powermenu: failed to launch '${a.label}':`, e)
  }
  quit()
}

    scheduleAutoclose()

    return (
      <window
        visible
        cssClasses={["powermenu"]}
        namespace="powermenu"
        layer={Astal.Layer.OVERLAY}
        anchor={TOP | BOTTOM | LEFT | RIGHT}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.EXCLUSIVE}
      >
        <Gtk.EventControllerKey
          onKeyPressed={(_self, keyval) => {
            if (keyval === Gdk.KEY_Escape) {
              confirming.get() ? cancelConfirm() : quit()
              return true
            }
            if (!confirming.get()) {
              const match = actions.find(a => a.key === Gdk.keyval_name(keyval))
              if (match) { selectAction(match); return true }
            }
            return false
          }}
        />
        <Gtk.GestureClick
          propagationPhase={Gtk.PropagationPhase.TARGET}
          onPressed={quit}
        />
        <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
          <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["pm-card"]}>
            <box cssClasses={["pm-header-box"]}>
              <label label="POWER MENU" cssClasses={["pm-header"]} halign={Gtk.Align.START} />
            </box>
            <With value={confirming}>
              {(c) => c
                ? <ConfirmView action={c} onConfirm={() => runAndQuit(c)} onCancel={cancelConfirm} />
                : <ActionList onSelect={selectAction} />
              }
            </With>
          </box>
        </box>
      </window>
    )
  },
})