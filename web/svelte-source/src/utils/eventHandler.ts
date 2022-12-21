import { onMount, onDestroy } from "svelte";
import methods from '../stores/exampleStore';

interface nuiMessage {
  data: {
    action: string,
    topic?: string,
    [key: string]: any,
  },
}

export function EventHandler() {
  function mainEvent(event: nuiMessage) {
    switch (event.data.action) {
      case "open":
        methods.showForm(event.data.data);
        break;
      case "update":
          methods.updateForm(event.data.data);
          break;
      case "forceClose":
        methods.closeForm();
        break;
    }
  }

  onMount(() => window.addEventListener("message", mainEvent));
  onDestroy(() => window.removeEventListener("message", mainEvent));
}
