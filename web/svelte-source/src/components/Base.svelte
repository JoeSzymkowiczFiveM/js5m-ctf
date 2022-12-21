<script>
    import { onMount } from "svelte";
    import exampleStore from '../stores/exampleStore';
    import methods from '../stores/exampleStore';

    let { data } = exampleStore;
    let currentData = [];

    onMount(() => {
        //$data = {allData: [{color: 'red', text: 'one'}, {color: 'blue', text: 'two'}]};
        currentData = $data.allData;

        updateUi();   
        
        //used for testing without backend - after backend testing can delete this if not needed
        // var intervalId = window.setInterval(function(){
        // let data1 = {allData: [{color: 'green', text: 'one'}, {color: 'blue', text: 'two'}]}; // definitely delete this line
        //  methods.updateForm(data1);
        // }, 5000);
    });

    function updateUi() {
        setTimeout(() => {
            currentData.forEach((element, idx) => {
                let key = 'child-'+idx.toString();
                let childOne = document.getElementById(key);
                childOne.style.backgroundColor = element.color;
            });
        }, 200); 
    }

    $: {
        if($data) {
            setTimeout(() => {
                currentData = $data.allData;
                updateUi();
            }, 200);
        }
    }

</script>
<div class="main-body">
    {#each currentData as element, idx}
        <div id="child-{idx}" class="inner-child" style="background-color: none;">
            <p>{element.text}</p>
        </div>
    {/each}
</div>