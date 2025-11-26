import { Button } from './components/ui/button'
import Versions from './components/Versions'

function App(): React.JSX.Element {
  const ipcHandle = (): void => window.electron.ipcRenderer.send('ping')

  return (
    <>
      <div className="text-2xl font-bold">Data Peek</div>
      <Button onClick={ipcHandle}>Send Ping</Button>
      <Versions></Versions>
    </>
  )
}

export default App
