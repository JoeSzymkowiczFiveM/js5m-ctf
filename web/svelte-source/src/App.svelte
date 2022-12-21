<script lang="ts">
  import { EventHandler } from './utils/eventHandler';
  import exampleStore from './stores/exampleStore'
  import methods from './stores/exampleStore'
  import Base from './components/Base.svelte';

  EventHandler();
  
  let { show } = exampleStore;
  document.onkeyup = methods.handleKeyUp;
</script>

{#if $show}
  <Base/>
{/if}
