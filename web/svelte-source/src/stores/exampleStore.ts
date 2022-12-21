import { Readable, readable, writable, Writable } from "svelte/store";
import fetchNUI from '../utils/fetch';

interface exampleState {
  show: Writable<boolean>
  data: Writable<any>
}

const store = () => {
  const year = new Date().getFullYear();
  const exampleStore: exampleState = {
    show: writable(false),
    data: writable({}),
  }

  const methods = {
    closeForm(value=null) {
      exampleStore.show.set(false);
      fetchNUI('closeMenu', value);
    },
    showForm(data) {
      exampleStore.show.set(true);
      exampleStore.data.set(data);
    },
    updateForm(data) {
      methods.showForm(data);
    },
    handleKeyUp(data) {
      if (data.key == "Escape") {
        methods.closeForm();
      }
    },
  }

  return {
    ...exampleStore,
    ...methods
  }
}

export default store();