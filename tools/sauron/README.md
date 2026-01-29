<h2>How to use the image</h2>

<h3>sauron</h3>
<p>sauron is a script that wrap the docker run command. It mount the required volumes and execute the command that you pass as an argument</p>
<p>The docker container is destroyed after the command</p>
<p>The following folder are the mounted volumes</p>
<ul>
    <li>rancher/:/root/.rancher/</li>
    <li>../../terraform/:/opt/terraform/</li>
</ul>

<h3> Auth to rancher </h3>
<pre>sauron login</pre>


<h3> Deploy the entire infra</h3>
<p>The command will deploy the entire cluster. The server and the workloads</p>
<p>Then it will log to the accurate project in rancher </p>
<pre>sauron setup</pre>

<h3> AWS</h3>
<h4> Awake </h4>
<p>Awake the ec2 instance of the rancher server that is in stop mode</p>
<pre>sauron awake-server</pre>
<h4> Stop </h4>
<p>Put the ec2 instance of the rancher server in stop mode</p>
<pre>sauron stop-server</pre>

<h3> RKE</h3>
<h4> Deploy </h4>
<p>Deploy the workload instances</p>
<pre>sauron deploy-rke</pre>
<h4> Destroy </h4>
<p>Destroy the workload instances</p>
<pre>sauron destroy-rke</pre>

<h3> Tests</h3>
<h4>How to read the tests filename</h4>
<p>The tests files scripts are named by the actions that they will do. You can find the relationship between a letter and the action it implies below.</p>
<ul>
<table>
    <thead>
        <tr>
            <th>Letter(s)</th>
            <th>Action</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>d</td>
            <td>deploy the all cluster</td>
        </tr>
        <tr>
            <td>ds</td>
            <td>destroy the all cluster</td>
        </tr>
        <tr>
            <td>d_r</td>
            <td>deploy the rke part</td>
        </tr>
        <tr>
            <td>ds_r</td>
            <td>destroy the rke part</td>
        </tr>
        <tr>
            <td>a</td>
            <td>awake the rancher server</td>
        </tr>
        <tr>
            <td>s</td>
            <td>stop the rancher server</td>
        </tr>
        <tr>
            <td>Xx_X-X_xX</td>
            <td>will run the commands surrounded by the Xx_ _xX X times. ex: 2x_s-a_x2 runs 2 times stop awake commands</td>
        </tr>
    </tbody>
</table>
</ul>
